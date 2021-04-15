// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./interfaces/IGYFIToken.sol";
import "./token/ERC677.sol";
import "./token/ERC677Receiver.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @title Yield farming token for GSDI.
/// @author jkp
contract GYFIToken is IGYFIToken, Ownable, ERC20Snapshot, ERC20Burnable, ERC677 {
    using SafeMath for uint256;

    mapping(address => bool) public isBlacklisted;

    constructor() ERC20("GYFIToken", "GYFI") {}

    /// @notice Allows the contract owner to blacklist accounts believed to be under the jurisdiction of the Securities Exchange Commission of the United States of America. Blacklisted accounts can send but not receive tokens.
    function usaSecJurisdictionBlacklist(address _account, bool _isBlacklisted) public override onlyOwner {
        isBlacklisted[_account] = _isBlacklisted;
    }

    // For ERC677 implementation, see https://github.com/smartcontractkit/LinkToken/blob/master/contracts/v0.6/ERC677Token.sol
    // For ERC677 explanation, see https://github.com/ethereum/EIPs/issues/677
    /// @notice Transfers tokens and immediately calls onTokenTransfer on the receiver.
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) public override (IGYFIToken, ERC677) returns (bool success) {
        transfer(to, value);

        emit Transfer(msg.sender, to, value, data);

        if (isContract(to)) {
            ERC677Receiver receiver = ERC677Receiver(to);
            receiver.onTokenTransfer(msg.sender, value, data);
        }
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override(ERC20, IERC20)
        returns (bool)
    {
        require(isBlacklisted[recipient] != true, "blacklisted user");

        return super.transfer(recipient, amount);
    }

    // PRIVATE

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) {
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
