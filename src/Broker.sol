// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Broker {
    address public lender;
    address public storage_provider;

    constructor(address _lender, address _storage_provider) {
        lender = _lender;
        storage_provider = _storage_provider;
    }

    function getLender() public view returns (address) {
        return lender;
    }

    function getStorageProvider() public view returns (address) {
        return storage_provider;
    }
}
