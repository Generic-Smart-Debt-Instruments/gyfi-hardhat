// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.3 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGYFIStrategy.sol";
import "./interfaces/IGYFIPool.sol";
import "./interfaces/IGYFIToken.sol";

/// @title Lending pool for purchasing GSDI via strategies.
/// @author devneser
contract GYFIPool is Ownable, IGYFIPool, ERC20Snapshot {

  // Strategy interface for implementing custom strategies to purchase GSDI
  IGYFIStrategy public override strategy;

  constructor(address _strategy) ERC20("GYFIPool", "GYFIPool") {
    strategy = IGYFIStrategy(_strategy);
  }

  /// @notice Mints shares valued at amount. Requires user to approve IGYFIStrategy for currency.
  /// @dev Uses IGYFIStrategy to find price. Calls IGYFIStrategy.deposit.
  /// @param _amountCurrency Amount of currency in wad to deposit.
  function mint(uint256 _amountCurrency) public override onlyOwner {
		_mint(owner(), _amountCurrency);
    if (allowance(msg.sender, address(strategy)) < _amountCurrency) {
      approve(address(strategy), _amountCurrency);
    }
    strategy.deposit(_amountCurrency);
    emit Mint(msg.sender, _amountCurrency);
  }

  /// @notice Burns shares valued at amount. Transfers currency equal to share value to sender.
  /// @dev Uses IGYFIStrategy to find price. Calls IGYFIStrategy.withdraw.
  function burn(uint256 _amountShares) public override onlyOwner {
		_burn(owner(), _amountShares);
    strategy.withdraw(_amountShares);
    emit Burn(msg.sender, _amountShares);
  }

  function snapshot() external override returns (uint256 snapshotId_) {
    snapshotId_ = _snapshot();
  }

  function balanceOfAt(address _account, uint256 _snapshotID)
      public view override(IGYFIPool, ERC20Snapshot)
      returns (uint256 balance_) {
    balance_ = balanceOfAt(_account, _snapshotID);
  }

  function totalSupplyAt(uint256 _snapshotID) 
      public view override(IGYFIPool, ERC20Snapshot) 
      returns (uint256 totalSupply_) {
    totalSupply_ = totalSupplyAt(_snapshotID);
  }
}
