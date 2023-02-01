// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Utils.sol";

import {console} from "forge-std/console.sol";

import "../src/Pool.sol";
import "../src/CosmicFil.sol";

contract PoolTest is Test {
    Utils internal utils;
    Pool public pool;
    CosmicFil cosmicFil;

    address payable[] internal users;

    address payable internal storageProvider;
    address payable internal lender;

    event StorageProviderDeposit(address from, uint256 value);
    event LenderDeposit(address from, uint256 value);
    event NewBrokerDeployed(address brokerInfo, address lender, address storageProvider);

    function setUp() public {
        utils = new Utils();
        pool = new Pool();
        cosmicFil = new CosmicFil("CosmicFil", "CFA");

        users = utils.createUsers(2);

        storageProvider = users[0];
        vm.label(storageProvider, "Storage Provider");

        lender = users[1];
        vm.label(lender, "Bob");

        cosmicFil.mint(storageProvider, 10e18);
        cosmicFil.mint(lender, 10e18);
    }

    function testLenderDeposits() public {
        vm.startPrank(lender);
        assertEq(cosmicFil.balanceOf(lender), 10e18);

        cosmicFil.approve(address(pool), 10e18);

        vm.expectEmit(false, false, false, true);
        emit LenderDeposit(address(lender), 1e18);

        pool.depositLender{value: 1e18}(address(cosmicFil));

        assertEq(cosmicFil.balanceOf(lender), 9e18);

        vm.stopPrank();
    }

    function testStorageProviderDeposits() public {
        vm.startPrank(storageProvider);
        assertEq(cosmicFil.balanceOf(storageProvider), 10e18);

        cosmicFil.approve(address(pool), 10e18);

        vm.expectEmit(false, false, false, true);
        emit StorageProviderDeposit(address(storageProvider), 1e18);

        pool.depositStorageProvider{value: 1e18}(address(cosmicFil));

        assertEq(cosmicFil.balanceOf(storageProvider), 9e18);

        vm.stopPrank();
    }
}
