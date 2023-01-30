// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Pool.sol";

contract PoolTest is Test {
    Pool public pool;

    event NewBrokerDeployed(address brokerInfo, address lender, address storageProvider);

    function setUp() public {
        pool = new Pool();
    }

    function testDeployBroker() public {
        address newBroker = pool.deployBroker(address(1), address(2));

        Pool.BrokerInfo memory broker = pool.getBrokerInfo(newBroker);

        assertEq(broker.lender, address(1));
        assertEq(broker.storageProvider, address(2));
    }

    function testExpectNewBrokerDeployedEvent() public {
        vm.expectEmit(false, false, false, true);
        address newBroker = pool.deployBroker(address(1), address(2));

        emit NewBrokerDeployed(address(newBroker), address(1), address(2));
    }
}
