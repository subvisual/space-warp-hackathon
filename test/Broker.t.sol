// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Broker.sol";

contract BrokerTest is Test {
    Broker public broker;

    function setUp() public {
        broker = new Broker(address(0x1), address(0x2),address(0x3), 1e18);
    }

    function testGetPool() public {
        assertEq(broker.getPool(), address(0x1));
    }

    function testGetStorageProvider() public {
        (address owner, address miner) = broker.getStorageProvider();

        assertEq(owner, address(0x2));
        assertEq(miner, address(0x3));
    }
}
