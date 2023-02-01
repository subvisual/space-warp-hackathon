// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract StorageProviderMock {
    address owner;
    address miner;

    constructor(address _owner, address _miner) {
        owner = _owner;
        miner = _miner;
    }
}
