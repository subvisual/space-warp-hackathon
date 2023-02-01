// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Broker {
    address public pool;
    address public storage_provider;
    uint256 public loanAmount;

    constructor(address _pool, address _storage_provider, uint256 _loanAmount) {
        pool = _pool;
        storage_provider = _storage_provider;
        loanAmount = _loanAmount;
    }

    function getPool() public view returns (address) {
        return pool;
    }

    function getStorageProvider() public view returns (address) {
        return storage_provider;
    }
}
