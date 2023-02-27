// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Utils.sol";

import "../src/Broker.sol";
import "../src/Pool.sol";

contract BrokerTest is Test {
    Utils internal utils;
    Broker public broker;
    Pool public pool;

    address payable[] internal users;
    address payable internal lender;

    function setUp() public {
        utils = new Utils();
        pool = new Pool();
        broker = new Broker(payable(address(pool)), address(0x2),address(0x3), 2 ether);

        users = utils.createUsers(1);

        lender = users[0];
    }

    function testGetStorageProvider() public {
        (address owner, address miner) = broker.getStorageProvider();

        assertEq(owner, address(0x2));
        assertEq(miner, address(0x3));
    }

    function testUpdatePool(uint256 reward) public {
        reward = bound(reward, 1 ether, 100 ether);

        uint256 totalLoan = 2 * reward;

        vm.startPrank(lender);
        pool.depositLender{value: reward}(lender);
        vm.stopPrank();

        assertEq(pool.tokensStaked(), reward);

        broker = new Broker(payable(address(pool)), address(0x2),address(0x3),  totalLoan);

        assertEq(broker.loanAmount(), totalLoan);

        vm.deal(address(broker), totalLoan);
        assertEq((address(broker).balance), totalLoan);

        assertEq(pool.lockedCapital(address(0x2)), 0);
        assertEq(pool.totalWorkingCapital(), reward);

        broker.reward(reward);

        assertEq(broker.loanAmount(), totalLoan - reward / 2);

        assertEq(pool.lockedCapital(address(0x2)), reward / 2);
        assertEq(pool.totalWorkingCapital(), reward + reward / 2);
    }
}
