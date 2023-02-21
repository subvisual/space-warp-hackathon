// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/bonds/ChickenBondManager.sol";
import "../src/bonds/BondNFT.sol";
import "../src/bonds/BFIL.sol";
import "./Utils.sol";

contract ChickenBondManagerTest is Test {
    Utils internal utils;
    BondNFT public bondNFT;
    Pool public pool;
    BFIL public bfilToken;
    ChickenBondManager public chickenBondManager;

    address payable[] internal users;
    address payable internal alice;
    address payable internal bob;
    address payable internal eve;

    event BondCreated(address indexed bonder, uint256 bondId, uint256 amount);

    event BondClaimed(
        address indexed bonder,
        uint256 bondId,
        uint256 lusdAmount,
        uint256 bLusdAmount,
        uint256 lusdSurplus,
        uint256 chickenInFeeAmount,
        bool migration
    );

    event BondCancelled(
        address indexed bonder,
        uint256 bondId,
        uint256 principalLusdAmount,
        uint256 minLusdAmount,
        uint256 withdrawnLusdAmount
    );

    event BLUSDRedeemed(
        address indexed redeemer,
        uint256 bLusdAmount,
        uint256 minLusdAmount,
        uint256 lusdAmount,
        uint256 yTokens,
        uint256 redemptionFee
    );

    event LenderDeposit(address indexed from, uint256 value);

    function setUp() public {
        utils = new Utils();
        bondNFT = new BondNFT("BOND", "BOND", "URI");
        pool = new Pool();
        bfilToken = new BFIL("BFIL", "BFIL");
        chickenBondManager = new ChickenBondManager(address(bondNFT),address(pool), address(bfilToken ),1 ether);

        bondNFT.setAddresses(address(chickenBondManager));
        pool.setAddresses(address(chickenBondManager));
        bfilToken.setAddresses(address(chickenBondManager));

        users = utils.createUsers(3);
        alice = users[0];
        bob = users[1];
        eve = users[2];

        vm.deal(address(alice), 100 ether);
        vm.deal(address(bob), 100 ether);
        vm.deal(address(eve), 100 ether);
    }

    function testFuzz_CreateBond(uint256 amount) public {
        vm.assume(amount >= 1 ether);
        vm.deal(alice, amount);

        vm.startPrank(alice);

        vm.expectEmit(true, false, false, true);
        emit BondCreated(alice, 1, amount);
        emit LenderDeposit(address(chickenBondManager), amount);

        chickenBondManager.createBond{value: amount}();

        uint256 pendingFil = chickenBondManager.getPendingfil();

        assertEq(pendingFil, amount);

        vm.stopPrank();
    }

    function test_RevertIf_ValueLowerThenMinBondAmount_CreateBond(uint256 amount) public {
        uint256 maxAmount = 1 ether - 1;
        amount = bound(amount, 0, maxAmount);
        vm.deal(alice, amount);

        vm.startPrank(alice);

        vm.expectRevert(BondAmountNotMet.selector);
        chickenBondManager.createBond{value: amount}();

        vm.stopPrank();
    }

    function testChickenIn(uint256 amount) public {
        vm.assume(amount >= 1 ether);
        vm.deal(alice, amount);

        vm.startPrank(alice);

        vm.expectEmit(true, false, false, true);
        emit BondCreated(alice, 1, amount);
        emit LenderDeposit(address(chickenBondManager), amount);

        uint256 bondId = chickenBondManager.createBond{value: amount}();

        uint256 pendingFil = chickenBondManager.getPendingfil();

        assertEq(pendingFil, amount);

        chickenBondManager.chickenIn(bondId);

        (uint256 filAmount, uint64 claimedBFIL, uint64 startTime, uint64 endTime, uint8 status) =
            chickenBondManager.getBondData(bondId);

        assertEq(claimedBFIL, 0);

        vm.stopPrank();
    }

    function testChickenOutNormalFlow(uint256 amount) public {
        vm.assume(amount >= 1 ether);
        vm.deal(alice, amount);

        vm.startPrank(alice);

        vm.expectEmit(true, false, false, true);
        emit BondCreated(alice, 1, amount);
        emit LenderDeposit(address(chickenBondManager), amount);

        uint256 bondId = chickenBondManager.createBond{value: amount}();

        uint256 pendingFil = chickenBondManager.getPendingfil();

        assertEq(pendingFil, amount);

        vm.expectEmit(true, false, false, true);
        emit BondCancelled(alice, 1, amount, 0, amount);
        chickenBondManager.chickenOut(bondId, 0);

        vm.stopPrank();
    }

    function testChickenOutMinFill(uint256 amount) public {
        vm.assume(amount >= 1 ether);
        vm.deal(alice, amount);

        vm.expectEmit(true, false, false, true);
        emit BondCreated(alice, 1, amount);
        emit LenderDeposit(address(chickenBondManager), amount);

        vm.prank(address(alice));
        uint256 bondId = chickenBondManager.createBond{value: amount}();

        uint256 pendingFil = chickenBondManager.getPendingfil();

        assertEq(pendingFil, amount);

        uint256 halfAmount = amount / 2;
        uint256 minFil = amount - halfAmount;

        vm.prank(address(chickenBondManager));
        pool.withdraw(msg.sender, halfAmount);

        vm.expectEmit(true, false, false, true);
        emit BondCancelled(alice, 1, amount, minFil, minFil);

        vm.prank(address(alice));
        chickenBondManager.chickenOut(bondId, minFil);
    }

    function test_RevertIf_ChickenOutNotEnoughFil(uint256 amount) public {
        //vm.assume(amount >= 1 ether );
        amount = bound(amount, 1 ether, 2 ** 255);
        vm.deal(alice, amount);

        vm.expectEmit(true, false, false, true);
        emit BondCreated(alice, 1, amount);
        emit LenderDeposit(address(chickenBondManager), amount);

        vm.prank(address(alice));
        uint256 bondId = chickenBondManager.createBond{value: amount}();

        uint256 pendingFil = chickenBondManager.getPendingfil();

        assertEq(pendingFil, amount);

        vm.prank(address(chickenBondManager));
        pool.withdraw(msg.sender, amount);

        vm.expectRevert(NotEnoughFilInPool.selector);
        vm.prank(address(alice));
        chickenBondManager.chickenOut(bondId, amount);
    }

    function testRedeem(uint256 amount) public {
        vm.assume(amount >= 1 ether);
        vm.deal(alice, amount);

        vm.startPrank(alice);

        vm.expectEmit(true, false, false, true);
        emit BondCreated(alice, 1, amount);
        emit LenderDeposit(address(chickenBondManager), amount);

        uint256 bondId = chickenBondManager.createBond{value: amount}();

        uint256 pendingFil = chickenBondManager.getPendingfil();

        assertEq(pendingFil, amount);

        chickenBondManager.chickenOut(bondId, 0);

        chickenBondManager.redeem(1, 0);
        vm.stopPrank();
    }
}
