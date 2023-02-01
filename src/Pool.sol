// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Broker.sol";
import "./StorageProviderMock.sol";
import "./CosmicFil.sol";

import {console} from "forge-std/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Deposit {}

contract Pool {
    CosmicFil cosmicFil;

    mapping(address => Broker) public loans;
    mapping(address => StorageProviderMock) public storageProviders;

    mapping(address => uint256) public lenderBalance;
    mapping(address => uint256) public storageProviderBalance;

    // Events
    event StorageProviderDeposit(address from, uint256 value);
    event LenderDeposit(address from, uint256 value);
    event NewBrokerDeployed(address brokerInfo, address storageProvider, uint256 amount);

    constructor() {
        cosmicFil = new CosmicFil("CosmicFil", "CFA");
    }

    function depositLender(address tokenAddress) public payable {
        require(msg.value > 0, "Amount must be greater than zero");

        CosmicFil token = CosmicFil(tokenAddress);

        require(token.balanceOf(msg.sender) >= msg.value, "Insufficient balance");

        token.transferFrom(msg.sender, address(this), msg.value);

        lenderBalance[msg.sender] += msg.value;

        emit LenderDeposit(msg.sender, msg.value);
    }

    function depositStorageProvider(address tokenAddress) public payable {
        require(msg.value > 0, "Amount must be greater than zero");

        CosmicFil token = CosmicFil(tokenAddress);

        require(token.balanceOf(msg.sender) >= msg.value, "Insufficient balance");

        token.transferFrom(msg.sender, address(this), msg.value);

        storageProviderBalance[msg.sender] += msg.value;

        emit StorageProviderDeposit(msg.sender, msg.value);
    }

    function requestLoan(address ownerSP, address minerSP, uint256 amount) external {
        StorageProviderMock mock = new StorageProviderMock(ownerSP, minerSP);
        address spAddress = address(mock);
        storageProviders[msg.sender] = mock;

        Broker b = new Broker(address(this), spAddress, amount);
        address newBrokerAddress = address(b);

        loans[msg.sender] = b;

        emit NewBrokerDeployed(newBrokerAddress, spAddress, amount);
    }


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
