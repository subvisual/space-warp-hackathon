// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Broker {
    address public pool;
    address public storageProviderOwner;
    address public storageProviderMiner;
    uint256 public loanAmount;

    constructor(address _pool, address _storageProviderOwner, address _storageProviderMiner, uint256 _loanAmount) {
        pool = _pool;
        storageProviderOwner = _storageProviderOwner;
        storageProviderMiner = _storageProviderMiner;
        loanAmount = _loanAmount;
    }

    function getPool() public view returns (address) {
        return pool;
    }

    function getStorageProvider() public view returns (address, address) {
        return (storageProviderOwner, storageProviderMiner);
    }
}
