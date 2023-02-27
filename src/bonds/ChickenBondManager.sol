// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Interfaces/IBondNFT.sol";
import "../Interfaces/IBFIL.sol";
import "../Interfaces/IPool.sol";

error BondAmountNotMet();
error BondNotOwner();
error BondNotActive();
error MinValueGreaterThanNominal();
error NotEnoughFilInPool();

contract ChickenBondManager is IChickenBondManager {
    IPool public immutable pool;
    IBondNFT public immutable bondNFT;
    IBFIL public immutable bfilToken;
    uint256 public immutable MIN_BOND_AMOUNT; // Minimum amount of fil that needs to be bonded
    uint256 public totalWeightedStartTimes; // Sum of `filAmount * startTime` for all outstanding bonds (used to tell weighted average bond age)
    bool public migration;
    uint256 public countChickenOut;
    uint256 public countChickenIn;
    mapping(uint256 => BondData) private idToBondData;
    uint256 private pendingfil; // Total pending fil
    uint256 private permanentfil; // Total pending fil

    constructor(address _bondNFT, address _pool, address _bfilToken, uint256 _MIN_BOND_AMOUNT) {
        bondNFT = IBondNFT(_bondNFT);
        pool = IPool(_pool);
        bfilToken = IBFIL(_bfilToken);
        MIN_BOND_AMOUNT = _MIN_BOND_AMOUNT;
    }

    function createBond() external payable returns (uint256) {
        if (msg.value < MIN_BOND_AMOUNT) revert BondAmountNotMet();

        uint256 bondID = bondNFT.mint(msg.sender);

        BondData memory bondData;
        bondData.filAmount = msg.value;
        bondData.startTime = uint64(block.timestamp);
        bondData.status = BondStatus.active;
        idToBondData[bondID] = bondData;

        pendingfil += msg.value;
        totalWeightedStartTimes += msg.value * block.timestamp;

        pool.depositLender{value: msg.value}(msg.sender);

        emit BondCreated(msg.sender, bondID, msg.value);

        return bondID;
    }

    function chickenOut(uint256 _bondID, uint256 _minFIL) external {
        BondData memory bond = idToBondData[_bondID];

        if (msg.sender != bondNFT.ownerOf(_bondID)) revert BondNotOwner();

        if (bond.status != BondStatus.active) revert BondNotActive();

        idToBondData[_bondID].status = BondStatus.chickenedOut;
        idToBondData[_bondID].endTime = uint64(block.timestamp);

        countChickenOut += 1;

        pendingfil -= bond.filAmount;
        totalWeightedStartTimes -= bond.filAmount * bond.startTime;

        uint256 filToWithdraw = _requireEnoughfilInPool(bond.filAmount, _minFIL);

        pool.withdraw(msg.sender, filToWithdraw);

        emit BondCancelled(msg.sender, _bondID, bond.filAmount, _minFIL, filToWithdraw);
    }

    function chickenIn(uint256 _bondID) external {
        BondData memory bond = idToBondData[_bondID];

        if (msg.sender != bondNFT.ownerOf(_bondID)) revert BondNotOwner();

        if (bond.status != BondStatus.active) revert BondNotActive();

        uint256 accruedBFIL = 1;
        uint256 filSurplus = 1;
        uint256 chickenInFeeAmount = 0;

        idToBondData[_bondID].claimedBFIL = uint64(Math.min(accruedBFIL / 1e18, type(uint64).max));
        idToBondData[_bondID].status = BondStatus.chickenedIn;
        idToBondData[_bondID].endTime = uint64(block.timestamp);

        countChickenIn += 1;

        pendingfil -= bond.filAmount;
        totalWeightedStartTimes -= bond.filAmount * bond.startTime;

        permanentfil += filSurplus;

        bfilToken.mint(msg.sender, accruedBFIL);

        emit BondClaimed(msg.sender, _bondID, bond.filAmount, accruedBFIL, filSurplus, chickenInFeeAmount, migration);
    }

    function redeem(uint256 _bFILToRedeem, uint256 _minFILFromBAMMSPVault) external returns (uint256, uint256) {
        return (0, 0);
    }

    function _requireEnoughfilInPool(uint256 _requestedFIL, uint256 _minFIL) internal view returns (uint256) {
        if (_requestedFIL < _minFIL) revert MinValueGreaterThanNominal();

        uint256 filInPool = address(pool).balance;

        if (filInPool < _minFIL) revert NotEnoughFilInPool();

        uint256 filToWithdraw = Math.min(_requestedFIL, filInPool);

        return filToWithdraw;
    }

    // Bond getters

    function getBondData(uint256 _bondID)
        external
        view
        returns (uint256 filAmount, uint64 claimedBFIL, uint64 startTime, uint64 endTime, uint8 status)
    {
        BondData memory bond = idToBondData[_bondID];
        return (bond.filAmount, bond.claimedBFIL, bond.startTime, bond.endTime, uint8(bond.status));
    }

    // Pending getter

    function getPendingfil() external view returns (uint256) {
        return pendingfil;
    }

    // Permanent getter

    function getPermanentfil() external view returns (uint256) {
        return permanentfil;
    }
}
