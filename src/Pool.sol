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

    // Events
    event StorageProviderDeposit(address from, uint256 value);
    event LenderDeposit(address from, uint256 value);
    event NewBrokerDeployed(address broker, address pool, address storageProvider, uint256 amount);

    constructor(address _cosmicFil) {
        cosmicFil = CosmicFil(_cosmicFil);
    }

    function depositLender() public payable {
        require(msg.value > 0, "Amount must be greater than zero");

        require(cosmicFil.balanceOf(msg.sender) >= msg.value, "Insufficient balance");

        cosmicFil.transferFrom(msg.sender, address(this), msg.value);

        lenderBalance[msg.sender] += msg.value;

        workingCapital += msg.value;

        emit LenderDeposit(msg.sender, msg.value);
    }

    function depositStorageProvider() public payable {
        require(msg.value > 0, "Amount must be greater than zero");

        require(cosmicFil.balanceOf(msg.sender) >= msg.value, "Insufficient balance");

        cosmicFil.transferFrom(msg.sender, address(this), msg.value);

        storageProviderBalance[msg.sender] += msg.value;

        emit StorageProviderDeposit(msg.sender, msg.value);
    }

    function requestLoan(address storageProvider, uint256 amount) external returns (address) {
        require(storageProviderBalance[msg.sender] >= amount, "Not enough collateral in the pool");
        require(workingCapital >= amount, "Not enough working collateral in the pool");

        Broker broker = new Broker(address(this), storageProvider, amount);

        cosmicFil.transfer(address(broker), amount * 2);

        storageProviderBalance[msg.sender] = 0;
        workingCapital -= amount;

        emit NewBrokerDeployed(address(broker), address(this), storageProvider, amount);

        return address(broker);
    }

    // function requestLoan(address ownerSP, address minerSP, uint256 amount) external {
    //     StorageProviderMock mock = new StorageProviderMock(ownerSP, minerSP);
    //     address spAddress = address(mock);
    //     storageProviders[msg.sender] = mock;
    //
    //     Broker b = new Broker(address(this), spAddress, amount);
    //     address newBrokerAddress = address(b);
    //
    //     loans[msg.sender] = b;
    //
    //     emit NewBrokerDeployed(newBrokerAddress, spAddress, amount);
    // }

    // function deployBroker(address _storageProvider) external returns (address) {
    //     Broker b = new Broker(_storageProvider);
    //
    //     address new_broker_address = address(b);
    //
    //     BrokerInfo memory brokerInfo = BrokerInfo(_lender, _storageProvider);
    //
    //     loans[new_broker_address] = brokerInfo;
    //
    //     emit NewBrokerDeployed(new_broker_address, _lender, _storageProvider);
    //
    //     return new_broker_address;
    // }
    //
    // function approve(uint256 amount) external {
    //   require(cosmicFil.balanceOf(msg.sender) > amount, "Not enough");
    //
    //   console.log(msg.sender);
    //   console.log(address(this));
    //
    //   cosmicFil.approve(address(this), 10e18);
    //
    //   uint256 new_allowance = cosmicFil.allowance(msg.sender, address(this));
    //
    //   console.log(new_allowance);
    //   console.log("approve");
    // }
    //
    // function deposit(uint256 amount) external {
    //   require(msg.sender.balance > amount, "Not enough");
    //   uint256 allowed = cosmicFil.allowance(msg.sender, address(this));
    //
    //   require(allowed > amount, "Not allowed");
    //
    //   cosmicFil.transferFrom(msg.sender, address(this), amount);
    // }
}
