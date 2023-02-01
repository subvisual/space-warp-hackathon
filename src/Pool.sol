// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Broker.sol";
import "./CosmicFil.sol";

import {console} from "forge-std/console.sol";

contract Pool {
    CosmicFil cosmicFil;

    struct BrokerInfo {
        address lender;
        address storageProvider;
    }

    mapping(address => BrokerInfo) public loans;

    event NewBrokerDeployed(address brokerInfo, address lender, address storageProvider);

    constructor() {
      cosmicFil = new CosmicFil("CosmicFil", "CFA");
    }

    function approve(uint256 amount) external {
      require(cosmicFil.balanceOf(msg.sender) > amount, "Not enough");

      console.log(msg.sender);
      console.log(address(this));

      cosmicFil.approve(address(this), 10e18);

      uint256 new_allowance = cosmicFil.allowance(msg.sender, address(this));

      console.log(new_allowance);
      console.log("approve");
    }

    function deposit(uint256 amount) external {
      require(msg.sender.balance > amount, "Not enough");
      uint256 allowed = cosmicFil.allowance(msg.sender, address(this));

      require(allowed > amount, "Not allowed");

      cosmicFil.transferFrom(msg.sender, address(this), amount);
    }

    function getBrokerInfo(address _brokerInfo) external view returns (BrokerInfo memory) {
        return loans[_brokerInfo];
    }

    function deployBroker(address _lender, address _storageProvider) external returns (address) {
        Broker b = new Broker(_lender, _storageProvider);

        address new_broker_address = address(b);

        BrokerInfo memory brokerInfo = BrokerInfo(_lender, _storageProvider);

        loans[new_broker_address] = brokerInfo;

        emit NewBrokerDeployed(new_broker_address, _lender, _storageProvider);

        return new_broker_address;
    }
}
