// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.3 <0.9.0;
import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockToken is ERC20 {
  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
      _mint(msg.sender, 10000000 ether);
  }
}
