// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Broker.sol";
import {console} from "forge-std/console.sol";

contract Pool {
    struct BrokerInfo {
        address lender;
        address storageProvider;
    }

    mapping(address => BrokerInfo) public loans;

    event NewBrokerDeployed(address brokerInfo, address lender, address storageProvider);

    function deposit(uint256 amount) external {
      require(msg.sender.balance > amount, "Not enough");

      console.log(msg.sender);

      payable(address(msg.sender)).transfer(amount);
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
