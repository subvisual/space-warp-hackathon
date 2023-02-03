// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/bonds/ChickenBondManager.sol";
import "../src/bonds/BondNFT.sol";
import "./Utils.sol";

contract ChickenBondManagerTest is Test {
    Utils internal utils;
    BondNFT public bondNFT;
    ChickenBondManager public chickenBondManager;

    address payable[] internal users;
    address payable internal alice;
    address payable internal bob;
    address payable internal eve;

    function setUp() public {
        utils = new Utils();
        bondNFT = new BondNFT("BOND", "BOND", "URI");
        chickenBondManager = new ChickenBondManager(address(bondNFT), 1 ether);
        users = utils.createUsers(3);
        alice = users[0];
        bob = users[1];
        eve = users[2];

        vm.deal(address(alice), 100 ether);
        vm.deal(address(bob), 100 ether);
        vm.deal(address(eve), 100 ether);
    }

    function testCreateBond() public {
        vm.startPrank(alice);
        chickenBondManager.createBond{value: 1 ether}(); 
        vm.stopPrank();
    }

    function testChickenIn() public {
    }

    function testChickenOut() public {
    }

    function testRedeem() public {
    }
}
