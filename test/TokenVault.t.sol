// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Utils.sol";

import "../src/TokenVault.sol";
import "../src/Share.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract TokenVaultTest is Test {
    Utils internal utils;
    Share public share;
    TokenVault public vault;
    address payable[] internal users;

    address alice;
    address bob;

    event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);

    function setUp() public {
        utils = new Utils();
        share = new Share();
        vault = new TokenVault(IERC20(share));

        users = utils.createUsers(4);
        alice = users[0];
        vm.label(alice, "Alice");

        bob = users[1];
        vm.label(bob, "Bob");
    }

    function testDeposit() public {
        vm.startPrank(alice);
        vm.warp(100);

        vm.expectEmit(true, false, false, true);
        emit Deposit(address(alice), 1 ether, 1 ether, 100);

        assertEq(address(vault).balance, 0);

        vault.deposit{value: 1 ether}();

        uint256 shareBalance = share.balanceOf(alice);
        assertEq(shareBalance, 1 ether);

        assertEq(address(vault).balance, 1 ether);

        vm.stopPrank();
    }

    function testWithdrawExceedsAmount() public {
        vm.startPrank(alice);

        vm.expectRevert("Withdraw amount exceeds balance");
        vault.withdraw(1 ether);

        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(alice);

        vault.deposit{value: 2 ether}();
        assertEq(address(vault).balance, 2 ether);

        vm.expectEmit(true, false, false, true);
        emit Withdraw(address(alice), 1 ether, 1 ether);

        uint256 totalShares = vault.totalShares();
        uint256 currentBalance = vault.balanceOf();

        uint256 withdrawAmount = currentBalance * 1 ether / totalShares;

        uint256 vaultBalance = address(vault).balance;

        assert(vaultBalance > withdrawAmount);

        share.approve(address(vault), withdrawAmount);
        uint256 shareBalance = share.balanceOf(alice);

        vault.withdraw(1 ether);

        assertEq(address(vault).balance, vaultBalance - withdrawAmount);
        assertEq(share.balanceOf(alice), shareBalance - withdrawAmount);

        vm.stopPrank();
    }
}
