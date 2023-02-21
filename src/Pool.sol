// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./Broker.sol";

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
    event HarvestRewards(address indexed user, uint256 amount);

    function depositLender(address lender) public payable {
        require(msg.value > 0, "Amount must be greater than zero");

        harvestRewards();

        PoolStaker storage staker = poolStakers[msg.sender];
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

    function withdraw(address manager, uint256 amount) external {
        payable(manager).transfer(amount);
    }

    //
    // onlyOwner
    //
    function setAddresses(address _chickenBondManagerAddress) external onlyOwner {
        chickenBondManagerAddress = _chickenBondManagerAddress;
    }

    fallback() external payable {}
    receive() external payable {}

    function harvestRewards() public {
        updatePool(address(0), 0);

        PoolStaker storage staker = poolStakers[msg.sender];
        uint256 rewards = staker.amount * accumulatedRewardsPerShare / REWARDS_PRECISION;
        uint256 rewardsToHarvest = rewards - staker.rewardDebt;

        staker.rewardDebt = rewards;

        if (rewardsToHarvest == 0) {
            return;
        }

        emit HarvestRewards(msg.sender, rewardsToHarvest);
        // payable(manager).transfer(rewardsToHarvest);
    }

    function updatePool(address _storageProvider, uint256 rewards) public {
        if (tokensStaked == 0 || rewards == 0) {
            return;
        }

        lockedCapital[_storageProvider] += rewards / 2;
        totalWorkingCapital += rewards / 2;

        accumulatedRewardsPerShare = accumulatedRewardsPerShare + (rewards * REWARDS_PRECISION / tokensStaked);
    }

    function _requireCallerIsChickenBondsManager() internal view {
        if (msg.sender != chickenBondManagerAddress) revert CallerNotChickenManager();
    }
}
