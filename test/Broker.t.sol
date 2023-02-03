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
        broker = new Broker(payable(address(pool)), address(0x2),address(0x3), 2 ether);
    }

    function testGetStorageProvider() public {
        (address owner, address miner) = broker.getStorageProvider();

        assertEq(owner, address(0x2));
        assertEq(miner, address(0x3));
    }

    function testUpdatePool(uint256 reward) public {
        reward = bound(reward, 1 ether, 100 ether);

        uint256 totalLoan = 2 * reward;

        broker = new Broker(payable(address(pool)), address(0x2),address(0x3),  totalLoan);

        assertEq(broker.loanAmount(), totalLoan);

        vm.deal(address(broker), totalLoan);
        assertEq((address(broker).balance), totalLoan);

        assertEq(pool.lockedCapital(address(0x2)), 0);
        assertEq(pool.totalWorkingCapital(), 0);

        broker.reward(reward);

        assertEq(broker.loanAmount(), totalLoan - reward / 2);

        assertEq(pool.lockedCapital(address(0x2)), reward / 2);
        assertEq(pool.totalWorkingCapital(), reward / 2);
    }
}
