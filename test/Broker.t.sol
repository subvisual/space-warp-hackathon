// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Broker.sol";

contract BrokerTest is Test {
    Broker public broker;

    function setUp() public {
        broker = new Broker(address(0x1), address(0x2));
    }

    function testGetLender() public {
        assertEq(broker.getLender(), address(0x1));
    }

    function testGetStorageProvider() public {
        assertEq(broker.getStorageProvider(), address(0x2));
    }
}
