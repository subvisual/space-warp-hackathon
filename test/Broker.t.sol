// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Broker.sol";
import "../src/Pool.sol";
import "../src/CosmicFil.sol";

contract BrokerTest is Test {
    Broker public broker;
    Pool public pool;
    CosmicFil public cosmicFil;

    function setUp() public {
        cosmicFil = new CosmicFil("CosmicFil", "CFA");
        pool = new Pool(address(cosmicFil));
        broker = new Broker(address(pool), address(0x2),address(0x3), 4e18);

        cosmicFil.mint(address(broker), 2e18);
    }

    function testGetStorageProvider() public {
        (address owner, address miner) = broker.getStorageProvider();

        assertEq(owner, address(0x2));
        assertEq(miner, address(0x3));
    }

    function testUpdatePool() public {
        assertEq(broker.loanAmount(), 4e18);

        assertEq(pool.totalWorkingCapital(), 0e18);
        assertEq(pool.lockedCapital(address(0x2)), 0e18);

        assertEq(cosmicFil.balanceOf(address(broker)), 2e18);

        broker.reward(2e18);
        assertEq(broker.loanAmount(), 3e18);
        assertEq(cosmicFil.balanceOf(address(broker)), 0e18);

        assertEq(pool.lockedCapital(address(0x2)), 1e18);
        assertEq(pool.totalWorkingCapital(), 1e18);
    }
}
