// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Utils.sol";

import "../src/Pool.sol";
import "../src/bonds/ChickenBondManager.sol";
import "../src/bonds/BondNFT.sol";
import "../src/bonds/BFIL.sol";

contract PoolTest is Test {
    Utils internal utils;
    Pool public pool;
    BondNFT public bondNFT;
    BFIL public bfilToken;
    ChickenBondManager public chickenBondManager;

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
    event WithdrawRewards(address indexed user, uint256 amount);

    fallback() external payable {}
    receive() external payable {}

    function setUp() public {
        utils = new Utils();
        pool = new Pool();
        bondNFT = new BondNFT("BOND", "BOND", "URI");
        bfilToken = new BFIL("BFIL", "BFIL");
        chickenBondManager = new ChickenBondManager(address(bondNFT),address(pool), address(bfilToken ),1 ether);

        users = utils.createUsers(4);

        storageProvider = users[0];
        vm.label(storageProvider, "Storage Provider Alice");

        lender = users[1];
        vm.label(lender, "Lender Alice");

        anotherStorageProvider = users[2];
        vm.label(anotherStorageProvider, "Storage Provider Bob");

        anotherLender = users[3];
        vm.label(anotherLender, "Lender Bob");

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

        pool.withdrawCollateral(address(this), 1 ether);
        assertEq(lender.balance, 100 ether);

        vm.stopPrank();
    }

    function testUpdatePoolNoTokensStaked() public {
        assertEq(pool.accumulatedRewardsPerShare(), 0);
        pool.updatePool{value: 0}(address(0), 0);
        assertEq(pool.accumulatedRewardsPerShare(), 0);
    }

    function testUpdatePoolNoRewards() public {
        vm.startPrank(lender);
        pool.depositLender{value: 1 ether}(lender);
        vm.stopPrank();

        assertEq(pool.accumulatedRewardsPerShare(), 0);
        assertEq(pool.tokensStaked(), 1 ether);
        pool.updatePool{value: 0}(address(0), 0);
        assertEq(pool.accumulatedRewardsPerShare(), 0);
    }

    function testUpdatePoolRewards() public {
        vm.startPrank(lender);
        pool.depositLender{value: 1 ether}(lender);
        vm.stopPrank();

        assertEq(pool.accumulatedRewardsPerShare(), 0);
        assertEq(pool.tokensStaked(), 1 ether);
        pool.updatePool{value: 1 ether}(address(0), 1 ether);
        assertEq(pool.accumulatedRewardsPerShare(), 1 ether);
    }

    function testHarvestRewardsDoesNotUpdateShare() public {
        vm.startPrank(lender);
        pool.depositLender{value: 1 ether}(lender);
        vm.stopPrank();

        assertEq(pool.accumulatedRewardsPerShare(), 0);
        assertEq(pool.tokensStaked(), 1 ether);

        assertEq(pool.accumulatedRewardsPerShare(), 0);
        assertEq(pool.tokensStaked(), 1 ether);
    }

    function testHarvestRewardsEmitsEvent() public {
        vm.startPrank(lender);
        pool.depositLender{value: 1 ether}(lender);
        vm.stopPrank();

        assertEq(pool.accumulatedRewardsPerShare(), 0);
        assertEq(pool.tokensStaked(), 1 ether);

        pool.updatePool{value: 2 ether}(address(1), 2 ether);
    }

    function testHarvestRewardsWithMultipleLendersAtSameTime(uint256 depositValue) public {
        depositValue = bound(depositValue, 1 ether, 100 ether);

        vm.startPrank(lender);
        pool.depositLender{value: depositValue}(lender);
        vm.stopPrank();

        vm.startPrank(anotherLender);
        pool.depositLender{value: depositValue}(anotherLender);
        vm.stopPrank();

        assertEq(pool.accumulatedRewardsPerShare(), 0);
        assertEq(pool.tokensStaked(), 2 * depositValue);

        pool.updatePool{value: 2 * depositValue}(address(1), 2 * depositValue);
    }

    function testHarvestRewardsWithMultipleLendersDifferentTime(uint256 depositValue) public {
        depositValue = bound(depositValue, 1 ether, 100 ether);

        vm.startPrank(lender);
        pool.depositLender{value: depositValue}(lender);

        vm.stopPrank();

        pool.updatePool{value: depositValue}(address(1), depositValue);

        vm.startPrank(anotherLender);

        pool.depositLender{value: depositValue}(anotherLender);
        assertEq(pool.tokensStaked(), 2 * depositValue);

        (,, uint256 rewardDebt) = pool.poolStakers(anotherLender);
        assertEq(rewardDebt, depositValue);

        vm.stopPrank();

        pool.updatePool{value: depositValue}(address(1), depositValue);
    }
}
