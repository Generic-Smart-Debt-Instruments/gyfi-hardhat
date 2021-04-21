// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

abstract contract ERC677 is IERC20Upgradeable {
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) public virtual returns (bool success);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );
}
