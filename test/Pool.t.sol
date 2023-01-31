// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../src/Pool.sol";
import "./Utils.sol";

contract PoolTest is Test {
  Utils internal utils;
  Pool public pool;

  address payable[] internal users;

  address payable internal alice;
  address internal bob;

  event NewBrokerDeployed(address brokerInfo, address lender, address storageProvider);

  function setUp() public {
    utils = new Utils();
    pool = new Pool();

    users = utils.createUsers(2);

    alice = users[0];
    vm.label(alice, "Alice");

    bob = users[1];
    vm.label(bob, "Bob");
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

  function testAliceDeposits() public {
    console.log("Starting");

    vm.prank(alice);
    assertEq(alice.balance, 100 ether);

    console.log("Depositing..");
    console.log(address(alice));

    pool.deposit(1 ether);

    assertEq(alice.balance, 99 ether);
  }
}
