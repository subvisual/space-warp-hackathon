// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CosmicFil.sol";

contract CosmicFilTest is Test {
    CosmicFil cosmicFil;

    address alice = vm.addr(0x1);
    address bob = vm.addr(0x2);

    function setUp() public {
        cosmicFil = new CosmicFil("CosmicFil", "CFA");
    }

    function testMint() public {
        cosmicFil.mint(alice, 2e18);
        assertEq(cosmicFil.totalSupply(), cosmicFil.balanceOf(alice));
    }

    function testTransfer() external {
        testMint();
        vm.startPrank(alice);
        cosmicFil.transfer(bob, 1e18);
        assertEq(cosmicFil.balanceOf(bob), 1e18);
        assertEq(cosmicFil.balanceOf(alice), 1e18);
        vm.stopPrank();
    }

    function testTransferFrom() external {
        testMint();
        vm.prank(alice);
        cosmicFil.approve(address(this), 1e18);
        assertTrue(cosmicFil.transferFrom(alice, bob, 1e18));
        assertEq(cosmicFil.balanceOf(bob), 1e18);
        assertEq(cosmicFil.balanceOf(alice), 1e18);
    }
}
