// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CosmicFil is ERC20 {
  constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

  function mint(address to, uint256 amount) public virtual {
    _mint(to, amount);
  }

  function burn(address from, uint amount) public virtual {
    _burn(from, amount);
  }
}
