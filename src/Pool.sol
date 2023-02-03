// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./Broker.sol";

contract Pool is Ownable {
    uint256 MAX_INT = 2 ** 256 - 1;

    mapping(address => Broker) public loans;

    mapping(address => uint256) public lenderBalance;
    mapping(address => uint256) public storageProviderBalance;
    mapping(address => uint256) public lockedCapital;

    uint256 public totalWorkingCapital;
    uint256 public totalLenderBalance;
    uint256 public totalStorageProviderBalance;
    uint256 public totalCollateral;

    address public chickenBondManagerAddress;

    error CallerNotChickenManager();

    constructor() {}

    // Events
    event StorageProviderDeposit(address indexed from, uint256 value);
    event LenderDeposit(address indexed from, uint256 value);
    event NewBrokerDeployed(
        address indexed broker,
        address indexed pool,
        address storageProviderOwner,
        address storageProviderMiner,
        uint256 amount
    );

    function depositLender(address lender) public payable {
        _requireCallerIsChickenBondsManager();

        require(msg.value > 0, "Amount must be greater than zero");

        lenderBalance[lender] += msg.value;
        totalLenderBalance += msg.value;
        totalWorkingCapital += msg.value;
        totalCollateral += msg.value;

        emit LenderDeposit(lender, msg.value);
    }

    function depositStorageProvider() public payable {
        require(msg.value > 0, "Amount must be greater than zero");

        storageProviderBalance[msg.sender] += msg.value;
        totalStorageProviderBalance += msg.value;
        totalCollateral += msg.value;

        emit StorageProviderDeposit(msg.sender, msg.value);
    }

    function requestLoan(address storageProviderOwner, address storageProviderMiner, uint256 amount)
        external
        returns (address)
    {
        require(amount * 2 < MAX_INT, "Too close to MAX INT");
        require(storageProviderBalance[msg.sender] >= amount, "Not enough collateral in the pool");
        require(totalWorkingCapital >= amount, "Not enough working collateral in the pool");

        Broker broker = new Broker(payable(address(this)), storageProviderOwner, storageProviderMiner, amount);

        payable(address(broker)).transfer(amount * 2);

        storageProviderBalance[msg.sender] -= amount;

        totalWorkingCapital -= amount;

        totalStorageProviderBalance -= amount;

        totalLenderBalance -= amount;

        totalCollateral -= amount * 2;

        emit NewBrokerDeployed(address(broker), address(this), storageProviderOwner, storageProviderMiner, amount);

        return address(broker);
    }

    function withdraw(address manager, uint256 amount) external {
        _requireCallerIsChickenBondsManager();
        payable(manager).transfer(amount);
    }

    //
    // onlyOwner
    //
    function setAddresses(address _chickenBondManagerAddress) external onlyOwner {
        chickenBondManagerAddress = _chickenBondManagerAddress;
        renounceOwnership();
    }

    fallback() external payable {}
    receive() external payable {}

    function updatePool(address _storageProvider, uint256 amount) public {
        lockedCapital[_storageProvider] += amount / 2;
        totalWorkingCapital += amount / 2;
    }

    function _requireCallerIsChickenBondsManager() internal view {
        if (msg.sender != chickenBondManagerAddress) revert CallerNotChickenManager();
    }
}
