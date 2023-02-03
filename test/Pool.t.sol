// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Utils.sol";

import "../src/Pool.sol";

contract PoolTest is Test {
    Utils internal utils;
    Pool public pool;

    address payable[] internal users;

    address payable internal storageProvider;
    address payable internal lender;
    address payable internal anotherStorageProvider;
    address payable internal anotherLender;

    event StorageProviderDeposit(address indexed from, uint256 value);
    event LenderDeposit(address indexed from, uint256 value);
    event NewBrokerDeployed(
        address broker,
        address pool,
        address storageProvider,
        address storageProviderOwner,
        address storageProviderMiner,
        uint256 amount
    );

    fallback() external payable {}
    receive() external payable {}

    function setUp() public {
        utils = new Utils();
        pool = new Pool();

        users = utils.createUsers(4);

        storageProvider = users[0];
        vm.label(storageProvider, "Storage Provider Alice");

        lender = users[1];
        vm.label(lender, "Lender Alice");

        anotherStorageProvider = users[2];
        vm.label(anotherStorageProvider, "Storage Provider Bob");

        anotherLender = users[3];
        vm.label(anotherLender, "Lender Bob");

        pool.setAddresses(lender);

        vm.deal(address(storageProvider), 100 ether);
        vm.deal(address(lender), 100 ether);
        vm.deal(address(anotherStorageProvider), 100 ether);
        vm.deal(address(anotherLender), 100 ether);
    }

    function testLenderDeposits() public {
        vm.startPrank(lender);
        assertEq(lender.balance, 100 ether);

        vm.expectEmit(true, false, false, true);
        emit LenderDeposit(address(lender), 1 ether);

        pool.depositLender{value: 1 ether}(lender);

        assertEq(lender.balance, 99 ether);

        vm.stopPrank();
    }

    function testStorageProviderDeposits() public {
        vm.startPrank(storageProvider);
        assertEq(storageProvider.balance, 100 ether);

        vm.expectEmit(true, false, false, true);
        emit StorageProviderDeposit(address(storageProvider), 1 ether);

        pool.depositStorageProvider{value: 1 ether}();

        assertEq(storageProvider.balance, 99 ether);

        vm.stopPrank();
    }

    function testRequestLoanNotEnoughCollateral() public {
        vm.startPrank(storageProvider);

        vm.expectRevert("Not enough collateral in the pool");
        pool.requestLoan(address(this), address(this), 1 ether);

        vm.stopPrank();
    }

    function testProperty(uint256 lenderDeposit) public {
        vm.assume(lenderDeposit != 0);

        vm.startPrank(lender);
        vm.deal(lender, lenderDeposit);

        assertEq(lender.balance, lenderDeposit);

        pool.depositLender{value: lenderDeposit}(lender);

        assertEq(lender.balance, 0);

        vm.stopPrank();
    }

    function testRequestLoanDeploysBroker(uint256 lenderDeposit) public {
        // TODO how to use vm.assume instead of bound
        // vm.assume(lenderDeposit != 0);
        lenderDeposit = bound(lenderDeposit, 1 ether, 10000 ether);

        uint256 storageDeposit = 4 * lenderDeposit;
        uint256 totalDeposit = lenderDeposit + storageDeposit;

        vm.deal(lender, lenderDeposit);
        vm.deal(storageProvider, storageDeposit);

        vm.startPrank(lender);
        assertEq(lender.balance, lenderDeposit);
        pool.depositLender{value: lenderDeposit}(lender);
        vm.stopPrank();

        vm.startPrank(storageProvider);

        assertEq(storageProvider.balance, storageDeposit);
        pool.depositStorageProvider{value: storageDeposit}();

        assertEq(pool.totalLenderBalance(), lenderDeposit);
        assertEq(pool.totalStorageProviderBalance(), storageDeposit);
        assertEq(pool.totalWorkingCapital(), lenderDeposit);
        assertEq(pool.totalCollateral(), totalDeposit);
        assertEq(payable(address(pool)).balance, totalDeposit);

        address broker = pool.requestLoan(address(this), address(this), lenderDeposit);

        assertEq(payable(address(broker)).balance, 2 * lenderDeposit);

        assertEq(pool.totalLenderBalance(), 0);
        assertEq(pool.totalStorageProviderBalance(), storageDeposit - lenderDeposit);
        assertEq(pool.totalCollateral(), totalDeposit - 2 * lenderDeposit);

        vm.stopPrank();
    }

    function testBalance() public {
        vm.startPrank(lender);
        pool.depositLender{value: 5 ether}(lender);

        assertEq(payable(address(pool)).balance, 5 ether);

        vm.stopPrank();
    }

    function testTotalLenderBalance() public {
        vm.startPrank(lender);
        pool.depositLender{value: 5 ether}(lender);
        pool.depositLender{value: 5 ether}(lender);
        vm.stopPrank();

        assertEq(pool.totalLenderBalance(), 10 ether);
    }

    function testTotalStorageProviderBalance() public {
        vm.startPrank(storageProvider);
        pool.depositStorageProvider{value: 5 ether}();
        vm.stopPrank();
        vm.startPrank(anotherStorageProvider);
        pool.depositStorageProvider{value: 5 ether}();
        vm.stopPrank();

        assertEq(pool.totalStorageProviderBalance(), 10 ether);
    }

    function testWithdraw() public {
        vm.deal(address(pool), 10 ether);

        assertEq(address(pool).balance, 10 ether);
        assertEq(lender.balance, 100 ether);

        vm.startPrank(lender);

        pool.withdraw(address(this), 1 ether);
        assertEq(lender.balance, 100 ether);

        vm.stopPrank();
    }
}
