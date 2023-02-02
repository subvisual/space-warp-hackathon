// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Broker.sol";
import "./StorageProviderMock.sol";
import "./CosmicFil.sol";

import {console} from "forge-std/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Pool {
    CosmicFil cosmicFil;

    mapping(address => Broker) public loans;
    mapping(address => StorageProviderMock) public storageProviders;

    mapping(address => uint256) public lenderBalance;
    mapping(address => uint256) public storageProviderBalance;

    uint256 public workingCapital;
    uint256 public totalLenderBalance;
    uint256 public totalStorageProviderBalance;
    uint256 public totalCollateral;

    // Events
    event StorageProviderDeposit(address from, uint256 value);
    event LenderDeposit(address from, uint256 value);
    event NewBrokerDeployed(
        address broker, address pool, address storageProviderOwner, address storageProviderMiner, uint256 amount
    );

    constructor(address _cosmicFil) {
        cosmicFil = CosmicFil(_cosmicFil);
    }

    function depositLender() public payable {
        require(msg.value > 0, "Amount must be greater than zero");

        require(cosmicFil.balanceOf(msg.sender) >= msg.value, "Insufficient balance");

        cosmicFil.transferFrom(msg.sender, address(this), msg.value);

        lenderBalance[msg.sender] += msg.value;
        totalLenderBalance += msg.value;
        workingCapital += msg.value;
        totalCollateral += msg.value;

        emit LenderDeposit(msg.sender, msg.value);
    }

    function depositStorageProvider() public payable {
        require(msg.value > 0, "Amount must be greater than zero");

        require(cosmicFil.balanceOf(msg.sender) >= msg.value, "Insufficient balance");

        cosmicFil.transferFrom(msg.sender, address(this), msg.value);

        storageProviderBalance[msg.sender] += msg.value;
        totalStorageProviderBalance += msg.value;
        totalCollateral += msg.value;

        emit StorageProviderDeposit(msg.sender, msg.value);
    }

    function balance() public view returns (uint256) {
        return cosmicFil.balanceOf(msg.sender);
    }

    function requestLoan(address storageProviderOwner, address storageProviderMiner, uint256 amount)
        external
        returns (address)
    {
        require(storageProviderBalance[msg.sender] >= amount, "Not enough collateral in the pool");
        require(workingCapital >= amount, "Not enough working collateral in the pool");

        Broker broker = new Broker(address(this), storageProviderOwner, storageProviderMiner, amount);

        cosmicFil.transfer(address(broker), amount * 2);

        storageProviderBalance[msg.sender] -= amount;
        workingCapital -= amount;
        totalStorageProviderBalance -= amount;
        totalLenderBalance -= amount;
        totalCollateral -= amount * 2;

        emit NewBrokerDeployed(address(broker), address(this), storageProviderOwner, storageProviderMiner, amount);

        return address(broker);
    }
}
