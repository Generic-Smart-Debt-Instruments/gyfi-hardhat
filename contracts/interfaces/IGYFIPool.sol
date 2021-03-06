// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.3 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IGYFIStrategy.sol";

/// @title Lending pool for purchasing GSDI via strategies.
/// @author Crypto Shipwright
interface IGYFIPool is IERC20Upgradeable {
    event Mint(address _staker, uint256 _amountCurrency);
    event Burn(address _staker, uint256 _amountShares);

    /// @notice IGYFIStrategy for the pool.
    /// @return strategy_ Address of the strategy.
    function strategy() external view returns (IGYFIStrategy strategy_);

    /// @notice Mints shares valued at amount. Requires user to approve IGYFIStrategy for currency.
    /// @dev Uses IGYFIStrategy to find price. Calls IGYFIStrategy.deposit.
    /// @param _amountCurrency Amount of currency in wad to deposit.
    function mint(uint256 _amountCurrency) external;

    /// @notice Burns shares valued at amount. Transfers currency equal to share value to sender.
    /// @dev Uses IGYFIStrategy to find price. Calls IGYFIStrategy.withdraw.
    function burn(uint256 _amountShares) external;

    // For snapshots, See openzeppelin's ERC20Snapshot.

    /// @notice Creates a new snapshot at the current block.
    function snapshot() external returns (uint256 _snapshotId);

    /**
     * @dev Retrieves the balance of `account` at snapshotID.
     */
    function balanceOfAt(address account, uint256 snapshotID)
        external
        view
        returns (uint256);

    /**
     * @dev Retrieves the total supply at snapshotID.
     */
    function totalSupplyAt(uint256 snapshotID) external view returns (uint256);
}
