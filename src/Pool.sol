// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Broker.sol";

import {console} from "forge-std/console.sol";

contract Pool {
    uint256 MAX_INT = 2 ** 256 - 1;

    mapping(address => Broker) public loans;

    mapping(address => uint256) public lenderBalance;
    mapping(address => uint256) public storageProviderBalance;
    mapping(address => uint256) public lockedCapital;

    uint256 public totalWorkingCapital;
    uint256 public totalLenderBalance;
    uint256 public totalStorageProviderBalance;
    uint256 public totalCollateral;

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
    event PoolUpdated(address indexed storageProvider, uint256 amount);

    function depositLender() public payable {
        require(msg.value > 0, "Amount must be greater than zero");

        lenderBalance[msg.sender] += msg.value;
        totalLenderBalance += msg.value;
        totalWorkingCapital += msg.value;
        totalCollateral += msg.value;

        emit LenderDeposit(msg.sender, msg.value);
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

        Broker broker = new Broker(address(this), storageProviderOwner, storageProviderMiner, amount);

        payable(address(broker)).transfer(amount * 2);

        if (amount >= storageProviderBalance[msg.sender]) {
            storageProviderBalance[msg.sender] = 0;
        } else {
            storageProviderBalance[msg.sender] -= amount;
        }

        if (amount >= totalWorkingCapital) {
            totalWorkingCapital = 0;
        } else {
            totalWorkingCapital -= amount;
        }

        if (amount >= totalStorageProviderBalance) {
            totalStorageProviderBalance -= 0;
        } else {
            totalStorageProviderBalance -= amount;
        }

        if (amount >= totalLenderBalance) {
            totalLenderBalance = 0;
        } else {
            totalLenderBalance -= amount;
        }

        if (amount * 2 >= totalCollateral) {
            totalCollateral = 0;
        } else {
            totalCollateral -= amount * 2;
        }

        emit NewBrokerDeployed(address(broker), address(this), storageProviderOwner, storageProviderMiner, amount);

        return address(broker);
    }

    function updatePool(address _storageProvider, uint256 amount) public {
        lockedCapital[_storageProvider] += amount / 2;
        totalWorkingCapital += amount / 2;

        emit PoolUpdated(_storageProvider, amount);
    }
}
