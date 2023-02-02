// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Broker.sol";
import "../src/Pool.sol";

contract BrokerTest is Test {
    Broker public broker;
    Pool public pool;

    function setUp() public {
        pool = new Pool();
        broker = new Broker(address(pool), address(0x2),address(0x3), 2 ether);
    }

    function testGetStorageProvider() public {
        (address owner, address miner) = broker.getStorageProvider();

        assertEq(owner, address(0x2));
        assertEq(miner, address(0x3));
    }

    function testUpdatePool() public {
        assertEq(broker.loanAmount(), 2 ether);
        vm.deal(address(broker), 2 ether);
        assertEq((address(broker).balance), 2 ether);

        // assertEq(pool.lockedCapital(address(0x2)), 0e18);
        // assertEq(pool.totalWorkingCapital(), 0e18);
        //
        // broker.reward(2e18);
        //
        // assertEq(broker.loanAmount(), 3e18);
        // assertEq(cosmicFil.balanceOf(address(broker)), 0e18);
        //
        // assertEq(pool.lockedCapital(address(0x2)), 1e18);
        // assertEq(pool.totalWorkingCapital(), 1e18);
    }
}
