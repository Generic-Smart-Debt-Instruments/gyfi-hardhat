// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.3 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IGYFIStrategy.sol";
import "./interfaces/IGYFIPool.sol";
import "./interfaces/IGYFIToken.sol";

/// @title Lending pool for purchasing GSDI via strategies.
/// @author devneser
contract GYFIPool is IGYFIPool, ERC20Snapshot {
  using SafeMath for uint256;

  // Strategy interface for implementing custom strategies to purchase GSDI
  IGYFIStrategy public override strategy;

  constructor(address _strategy) ERC20("GYFIPool", "GYFIPool") {
    strategy = IGYFIStrategy(_strategy);
  }

  /// @notice Mints shares valued at amount. Requires user to approve IGYFIStrategy for currency.
  /// @dev Uses IGYFIStrategy to find price. Calls IGYFIStrategy.deposit.
  /// @param _amountCurrency Amount of currency in wad to deposit.
  function mint(uint256 _amountCurrency) public override {
		_mint(msg.sender, _amountCurrency);
    uint256 _amountDeposit = _amountCurrency.mul(totalSupply()).div(strategy.totalValue());
    strategy.deposit(_amountDeposit, msg.sender);
    emit Mint(msg.sender, _amountCurrency);
  }

  /// @notice Burns shares valued at amount. Transfers currency equal to share value to sender.
  /// @dev Uses IGYFIStrategy to find price. Calls IGYFIStrategy.withdraw.
  function burn(uint256 _amountShares) public override {
		_burn(msg.sender, _amountShares);
    uint256 _amountWithdraw = _amountShares.mul(strategy.totalValue()).div(totalSupply());
    strategy.withdraw(_amountWithdraw, msg.sender);
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
