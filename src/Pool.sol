// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./Broker.sol";
import "./Interfaces/IChickenBondManager.sol";

contract Pool is Ownable {
    uint256 MAX_INT = 2 ** 256 - 1;
    uint256 private constant REWARDS_PRECISION = 1e18;

    mapping(address => Broker) public loans;

    mapping(address => uint256) public lenderBalance;
    mapping(address => uint256) public storageProviderBalance;
    mapping(address => uint256) public lockedCapital;

    struct PoolStaker {
        uint256 amount;
        uint256 rewards;
        uint256 rewardDebt;
    }

    mapping(address => PoolStaker) public poolStakers;

    uint256 public tokensStaked;
    uint256 public accumulatedRewardsPerShare;

    uint256 public totalWorkingCapital;
    uint256 public totalLenderBalance;
    uint256 public totalStorageProviderBalance;
    uint256 public totalCollateral;

    address public chickenBondManagerAddress;

    error CallerNotChickenManager();

    constructor() {}
    fallback() external payable {}
    receive() external payable {}

    // Events
    event StorageProviderDeposit(address indexed from, uint256 value);
    event LenderDeposit(address indexed from, uint256 value);
    event NewBrokerDeployed(
        address indexed broker,
        address indexed pool,
        address storageProviderOwner,
        address storageProviderMiner,
        uint256 amount
    );
    event WithdrawRewards(address indexed user, uint256 amount);
    event WithdrawCollateral(address indexed user, uint256 amount);

    function depositLender(address lender) public payable {
        require(msg.value > 0, "Amount must be greater than zero");

        PoolStaker storage staker = poolStakers[lender];
        staker.amount = staker.amount + msg.value;
        staker.rewardDebt = staker.amount * accumulatedRewardsPerShare / REWARDS_PRECISION;

        lenderBalance[lender] += msg.value;
        totalLenderBalance += msg.value;
        totalWorkingCapital += msg.value;
        totalCollateral += msg.value;

        tokensStaked = tokensStaked + msg.value;
        emit LenderDeposit(lender, msg.value);
    }

    function depositStorageProvider() public payable {
        require(msg.value > 0, "Amount must be greater than zero");

        storageProviderBalance[msg.sender] += msg.value;
        totalStorageProviderBalance += msg.value;
        totalCollateral += msg.value;

        emit StorageProviderDeposit(msg.sender, msg.value);
    }

    function requestLoan(address storageProviderOwner, address storageProviderMiner, uint256 amount)
        external
        returns (address)
    {
        require(amount * 2 < MAX_INT, "Too close to MAX INT");
        require(storageProviderBalance[msg.sender] >= amount, "Not enough collateral in the pool");
        require(totalWorkingCapital >= amount, "Not enough working collateral in the pool");

        Broker broker = new Broker(payable(address(this)), storageProviderOwner, storageProviderMiner, amount);

        payable(address(broker)).transfer(amount * 2);

        storageProviderBalance[msg.sender] -= amount;

        totalWorkingCapital -= amount;

        totalStorageProviderBalance -= amount;

        totalLenderBalance -= amount;

        totalCollateral -= amount * 2;

        emit NewBrokerDeployed(address(broker), address(this), storageProviderOwner, storageProviderMiner, amount);

        return address(broker);
    }

    function withdrawCollateral(address lender, uint256 amount) external {
        if (amount == 0) {
            return;
        }

        PoolStaker storage staker = poolStakers[lender];

        if (staker.amount == 0) {
            return;
        }

        if (staker.amount - amount > 0) {
            staker.amount = staker.amount - amount;
        } else {
            staker.amount = 0;
        }

        staker.rewardDebt = staker.amount * accumulatedRewardsPerShare / REWARDS_PRECISION;

        tokensStaked = tokensStaked - amount;

        payable(lender).transfer(amount);

        emit WithdrawCollateral(lender, amount);
    }

    function withdrawRewards(address lender, uint256 amount) external {
        if (amount == 0 || amount > this.calculateRewards(lender, amount)) {
            return;
        }

        PoolStaker storage staker = poolStakers[lender];

        if (staker.amount == 0) {
            return;
        }

        staker.rewardDebt += amount;

        payable(lender).transfer(amount);

        emit WithdrawRewards(lender, amount);
    }

    function calculateRewards(address lender, uint256 amount) external view returns (uint256) {
        PoolStaker storage staker = poolStakers[lender];

        uint256 rewards = amount * accumulatedRewardsPerShare / REWARDS_PRECISION;
        uint256 rewardsToHarvest = rewards - staker.rewardDebt;

        return rewardsToHarvest;
    }

    function updatePool(address _storageProvider, uint256 rewards) external payable {
        if (tokensStaked == 0 || rewards == 0) {
            return;
        }

        lockedCapital[_storageProvider] += rewards / 2;
        totalWorkingCapital += rewards / 2;

        accumulatedRewardsPerShare = accumulatedRewardsPerShare + (rewards * REWARDS_PRECISION / tokensStaked);
    }
}
