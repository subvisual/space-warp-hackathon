// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Pool.sol";

contract Broker {
    Pool public pool;
    address public storageProviderOwner;
    address public storageProviderMiner;
    uint256 public loanAmount;

    constructor(
        address payable _pool,
        address _storageProviderOwner,
        address _storageProviderMiner,
        uint256 _loanAmount
    ) {
        pool = Pool(_pool);
        storageProviderOwner = _storageProviderOwner;
        storageProviderMiner = _storageProviderMiner;
        loanAmount = _loanAmount;
    }

    fallback() external payable {}
    receive() external payable {}

    event PoolUpdated(address indexed storageProviderOwner, address indexed pool, uint256 indexed amount);

    function getStorageProvider() public view returns (address, address) {
        return (storageProviderOwner, storageProviderMiner);
    }

    function reward(uint256 amount) public {
        pool.updatePool(storageProviderOwner, amount);

        loanAmount -= (amount / 2);

        payable(address(pool)).transfer(amount);

        emit PoolUpdated(storageProviderOwner, address(pool), amount);
    }
}
