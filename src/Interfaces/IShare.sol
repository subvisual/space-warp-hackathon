// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IShare {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}
