// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Pool.sol";

contract Broker {
    Pool public pool;
    address public storageProviderOwner;
    address public storageProviderMiner;
    uint256 public loanAmount;

    constructor(address _pool, address _storageProviderOwner, address _storageProviderMiner, uint256 _loanAmount) {
        pool = Pool(_pool);
        storageProviderOwner = _storageProviderOwner;
        storageProviderMiner = _storageProviderMiner;
        loanAmount = _loanAmount;
    }

    fallback() external payable {}

    function getStorageProvider() public view returns (address, address) {
        return (storageProviderOwner, storageProviderMiner);
    }


    function reward(uint256 amount) public {
        pool.updatePool(storageProviderOwner, amount);

        loanAmount -= (amount / 2);

        // address payable broker = payable(address(this));
        // broker.transfer(address(pool), amount);
    }
}
