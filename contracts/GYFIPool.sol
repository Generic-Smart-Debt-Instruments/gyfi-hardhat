// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.3 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IGYFIStrategy.sol";
import "./interfaces/IGYFIPool.sol";
import "./interfaces/IGYFIToken.sol";

/// @title Lending pool for purchasing GSDI via strategies.
/// @author devneser
contract GYFIPool is IGYFIPool, ERC20 {

  using Math for uint256;

  /// @dev `Checkpoint` is the structure that attaches a block number to a
  ///  given value, the block number attached is the one that last changed the
  ///  value
  struct Checkpoint {
      // `fromBlock` is the block number that the value was generated from
      uint128 fromBlock;
      // `value` is the amount of tokens at a specific block number
      uint128 value;
  }

  // `balances` is the map that tracks the balance of each address, in this
  //  contract when the balance changes the block number that the change
  //  occurred is also included in the map
  mapping (address => Checkpoint[]) balances;

  // `parentToken` is the Token address that was cloned to produce this token;
  //  it will be 0x0 for a token that was not cloned
  GYFIPool public parentToken;

  // `parentSnapShotBlock` is the block number from the Parent Token that was
  //  used to determine the initial distribution of the Clone Token
  uint256 public parentSnapShotBlock;

  // Tracks the history of the `totalSupply` of the token
  Checkpoint[] totalSupplyHistory;

  // Strategy interface for implementing custom strategies to purchase GSDI
  IGYFIStrategy public override strategy;

  constructor(address _strategy) ERC20("GYFIPool", "GYFIPool") {
    strategy = IGYFIStrategy(_strategy);
  }

  /// @notice Mints shares valued at amount. Requires user to approve IGYFIStrategy for currency.
  /// @dev Uses IGYFIStrategy to find price. Calls IGYFIStrategy.deposit.
  /// @param _amountCurrency Amount of currency in wad to deposit.
  function mint(uint256 _amountCurrency) external override {
    require(msg.sender != address(0), "GYFIPool: mint to the zero address");
    _generateTokens(msg.sender, _amountCurrency);
    if (allowance(msg.sender, address(strategy)) < _amountCurrency) {
      approve(address(strategy), _amountCurrency);
    }
    strategy.deposit(_amountCurrency);
    emit Mint(msg.sender, _amountCurrency);
  }

  /// @notice Burns shares valued at amount. Transfers currency equal to share value to sender.
  /// @dev Uses IGYFIStrategy to find price. Calls IGYFIStrategy.withdraw.
  function burn(uint256 _amountShares) external override {
    require(msg.sender != address(0), "GYFIPool: burn from the zero address");
    _destroyTokens(msg.sender, _amountShares);
    strategy.withdraw(_amountShares);
    emit Burn(msg.sender, _amountShares);
  }

  /**
    * @dev Retrieves the balance of `account` at the blockNumber.
    */
  function balanceOfAt(address account, uint256 blockNumber)
      external
      view
      override
      returns (uint256) {

      // These next few lines are used when the balance of the token is
      //  requested before a check point was ever created for this token, it
      //  requires that the `parentToken.balanceOfAt` be queried at the
      //  genesis block for that token as this contains initial balance of
      //  this token
      if ((balances[account].length == 0)
          || (balances[account][0].fromBlock > blockNumber)) {
          if (address(parentToken) != address(0)) {
              return parentToken.balanceOfAt(account, blockNumber.min(parentSnapShotBlock));
          } else {
              // Has no parent
              return 0;
          }

      // This will return the expected balance during normal situations
      } else {
          return _getValueAt(balances[account], blockNumber);
      }
  }

  /**
    * @dev Retrieves the total supply at the blockNumber.
    */
  function totalSupplyAt(uint256 blockNumber)
      external
      view
      override
      returns (uint256) {
      // These next few lines are used when the totalSupply of the token is
      //  requested before a check point was ever created for this token, it
      //  requires that the `parentToken.totalSupplyAt` be queried at the
      //  genesis block for this token as that contains totalSupply of this
      //  token at this block number.
      if ((totalSupplyHistory.length == 0)
          || (totalSupplyHistory[0].fromBlock > blockNumber)) {
          if (address(parentToken) != address(0)) {
              return parentToken.totalSupplyAt(blockNumber.min(parentSnapShotBlock));
          } else {
              return 0;
          }

      // This will return the expected totalSupply during normal situations
      } else {
          return _getValueAt(totalSupplyHistory, blockNumber);
      }
  }


  ////////////////
  // Generate and destroy tokens
  ////////////////

  /// @notice Generates `_amount` tokens that are assigned to `_owner`
  /// @param _owner The address that will be assigned the new tokens
  /// @param _amount The quantity of tokens generated
  /// @return True if the tokens are generated correctly
  function _generateTokens(address _owner, uint _amount) 
      public returns (bool) {
      uint curTotalSupply = totalSupply();
      require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
      uint previousBalanceTo = balanceOf(_owner);
      require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
      _updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
      _updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
      Transfer(address(0), _owner, _amount);
      return true;
  }


  /// @notice Burns `_amount` tokens from `_owner`
  /// @param _owner The address that will lose the tokens
  /// @param _amount The quantity of tokens to burn
  /// @return True if the tokens are burned correctly
  function _destroyTokens(address _owner, uint _amount)
      public returns (bool) {
      uint curTotalSupply = totalSupply();
      require(curTotalSupply >= _amount);
      uint previousBalanceFrom = balanceOf(_owner);
      require(previousBalanceFrom >= _amount);
      _updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
      _updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
      Transfer(_owner, address(0), _amount);
      return true;
  }

  /// @dev `updateValueAtNow` used to update the `balances` map and the
  ///  `totalSupplyHistory`
  /// @param checkpoints The history of data being updated
  /// @param _value The new number of tokens
  function _updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
      if ((checkpoints.length == 0)
      || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
              Checkpoint storage newCheckPoint = checkpoints[checkpoints.length+1];
              newCheckPoint.fromBlock =  uint128(block.number);
              newCheckPoint.value = uint128(_value);
          } else {
              Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
              oldCheckPoint.value = uint128(_value);
          }
  }

  /// @dev `getValueAt` retrieves the number of tokens at a given block number
  /// @param checkpoints The history of values being queried
  /// @param _block The block number to retrieve the value at
  /// @return The number of tokens being queried
  function _getValueAt(Checkpoint[] storage checkpoints, uint _block) internal view returns (uint) {
      if (checkpoints.length == 0) return 0;

      // Shortcut for the actual value
      if (_block >= checkpoints[checkpoints.length-1].fromBlock)
          return checkpoints[checkpoints.length-1].value;
      if (_block < checkpoints[0].fromBlock) return 0;

      // Binary search of the value in the array
      uint min = 0;
      uint max = checkpoints.length-1;
      while (max > min) {
          uint mid = (max + min + 1)/ 2;
          if (checkpoints[mid].fromBlock<=_block) {
              min = mid;
          } else {
              max = mid-1;
          }
      }
      return checkpoints[min].value;
  }
}
