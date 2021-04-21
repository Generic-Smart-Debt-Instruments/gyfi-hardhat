// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./interfaces/IGYFIToken.sol";
import "./token/ERC677.sol";
import "./token/ERC677Receiver.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @title Yield farming token for GSDI.
/// @author jkp
contract GYFIToken is
    IGYFIToken,
    OwnableUpgradeable,
    ERC20SnapshotUpgradeable,
    ERC20BurnableUpgradeable,
    ERC677
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;

    mapping(address => bool) public isBlacklisted;

    function intialize() public initializer {
        __ERC20_init("GYFIToken", "GYFI");
        _mint(msg.sender, 10000000 ether);
    }

    /// @notice Allows the contract owner to blacklist accounts believed to be under the jurisdiction of the Securities Exchange Commission of the United States of America. Blacklisted accounts can send but not receive tokens.
    function usaSecJurisdictionBlacklist(address _account, bool _isBlacklisted)
        public
        override
        onlyOwner
    {
        isBlacklisted[_account] = _isBlacklisted;
    }

    // For ERC677 implementation, see https://github.com/smartcontractkit/LinkToken/blob/master/contracts/v0.6/ERC677Token.sol
    // For ERC677 explanation, see https://github.com/ethereum/EIPs/issues/677
    /// @notice Transfers tokens and immediately calls onTokenTransfer on the receiver.
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) public override(IGYFIToken, ERC677) returns (bool success) {
        transfer(to, value);

        emit Transfer(msg.sender, to, value, data);

        if (isContract(to)) {
            ERC677Receiver receiver = ERC677Receiver(to);
            receiver.onTokenTransfer(msg.sender, value, data);
        }
        return true;
    }

    /// @notice Creates a new snapshot at the current block.
    function snapshot() external override returns (uint256 _snapshotId) {
        return _snapshot();
    }

    function balanceOfAt(address account, uint256 snapshotId)
        public
        view
        override(ERC20SnapshotUpgradeable, IGYFIToken)
        returns (uint256)
    {
        return ERC20SnapshotUpgradeable.balanceOfAt(account, snapshotId);
    }

    function totalSupplyAt(uint256 snapshotId)
        public
        view
        override(ERC20SnapshotUpgradeable, IGYFIToken)
        returns (uint256)
    {
        return ERC20SnapshotUpgradeable.totalSupplyAt(snapshotId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20SnapshotUpgradeable) {
        require(isBlacklisted[to] != true, "GYFIToken: Blacklisted user");
        super._beforeTokenTransfer(from, to, amount);
    }

    function isContract(address _addr) private view returns (bool hasCode) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
        return length > 0;
    }
}
