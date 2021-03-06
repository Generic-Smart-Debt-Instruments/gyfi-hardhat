// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.3 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title Yield farming token for GSDI.
/// @author Crypto Shipwright
interface IGYFIToken is IERC20Upgradeable {
    /// @notice Allows the contract owner to blacklist accounts believed to be under the jurisdiction of the Securities Exchange Commission of the United States of America. Blacklisted accounts can send but not receive tokens.
    function usaSecJurisdictionBlacklist(address account, bool isBlacklisted)
        external;

    // For ERC677 implementation, see https://github.com/smartcontractkit/LinkToken/blob/master/contracts/v0.6/ERC677Token.sol
    // For ERC677 explanation, see https://github.com/ethereum/EIPs/issues/677
    /// @notice Transfers tokens and immediately calls onTokenTransfer on the receiver.
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);

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
