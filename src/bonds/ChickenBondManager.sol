// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Interfaces/IBondNFT.sol";
import "../Interfaces/IBFIL.sol";
import "../Interfaces/IPool.sol";

// import "forge-std/console.sol";

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
    uint256 private pendingfil; // Total pending fil. It will always be in SP (B.Protocol)
    uint256 private permanentfil; // Total pending fil. It will always be in SP (B.Protocol)

    constructor(address _bondNFT, address _pool, address _bfilToken, uint256 _MIN_BOND_AMOUNT) {
        bondNFT = IBondNFT(_bondNFT);
        pool = IPool(_pool);
        bfilToken = IBFIL(_bfilToken);
        MIN_BOND_AMOUNT = _MIN_BOND_AMOUNT;
    }

    function createBond() external payable returns (uint256) {
        if (msg.value < MIN_BOND_AMOUNT) revert BondAmountNotMet();

        //_updateAccrualParameter();

        // Mint the bond NFT to the caller and get the bond ID
        uint256 bondID = bondNFT.mint(msg.sender);

        //Record the user’s bond data: bond_amount and start_time
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

        ////_updateAccrualParameter();

        idToBondData[_bondID].status = BondStatus.chickenedOut;
        idToBondData[_bondID].endTime = uint64(block.timestamp);

        countChickenOut += 1;

        pendingfil -= bond.filAmount;
        totalWeightedStartTimes -= bond.filAmount * bond.startTime;

        uint256 filToWithdraw = _requireEnoughfilInPool(bond.filAmount, _minFIL);

        //// Withdraw from B.Protocol fil vault
        pool.withdraw(msg.sender, filToWithdraw);

        emit BondCancelled(msg.sender, _bondID, bond.filAmount, bond.filAmount, bond.filAmount);
    }

    function chickenIn(uint256 _bondID) external {
        BondData memory bond = idToBondData[_bondID];

        if (msg.sender != bondNFT.ownerOf(_bondID)) revert BondNotOwner();

        if (bond.status != BondStatus.active) revert BondNotActive();

        //uint256 updatedAccrualParameter = _updateAccrualParameter();
        //(uint256 bammfilValue, uint256 filInBAMMSPVault) = _updateBAMMDebt();

        //(uint256 chickenInFeeAmount, uint256 bondAmountMinusChickenInFee) =
        //    _getBondWithChickenInFeeApplied(bond.filAmount);

        /* Upon the first chicken-in after a) system deployment or b) redemption of the full bfil supply, divert
        * any earned yield to the bfil-fil AMM for fairness.
        *
        * This is not done in migration mode since there is no need to send rewards to the staking contract.
        */
        //if (bfilToken.totalSupply() == 0 && !migration) {
        //    filInBAMMSPVault = _firstChickenIn(bond.startTime, bammfilValue, filInBAMMSPVault);
        //}

        // Get the fil amount to acquire from the bond in proportion to the system's current backing ratio, in order to maintain said ratio.
        //uint256 filToAcquire = _calcAccruedAmount(bond.startTime, bondAmountMinusChickenInFee, updatedAccrualParameter);
        //// Get backing ratio and accrued bfil
        //uint256 backingRatio = _calcSystemBackingRatioFromBAMMValue(bammfilValue);
        //uint256 accruedBFIL = filToAcquire * 1e18 / backingRatio;

        uint256 accruedBFIL = 1;
        uint256 filSurplus = 1;
        uint256 chickenInFeeAmount = 0;

        idToBondData[_bondID].claimedBFIL = uint64(Math.min(accruedBFIL / 1e18, type(uint64).max));
        idToBondData[_bondID].status = BondStatus.chickenedIn;
        idToBondData[_bondID].endTime = uint64(block.timestamp);

        countChickenIn += 1;

        // Subtract the bonded amount from the total pending fil (and implicitly increase the total acquired fil)
        pendingfil -= bond.filAmount;
        totalWeightedStartTimes -= bond.filAmount * bond.startTime;

        // Get the remaining surplus from the fil amount to acquire from the bond
        //uint256 filSurplus = bondAmountMinusChickenInFee - filToAcquire;

        // Handle the surplus fil from the chicken-in:
        // In normal mode, add the surplus to the permanent bucket by increasing the permament tracker. This implicitly decreases the acquired fil.
        permanentfil += filSurplus;

        bfilToken.mint(msg.sender, accruedBFIL);

        // Transfer the chicken in fee to the fil/bfil AMM LP Rewards staking contract during normal mode.
        //if (!migration && filInBAMMSPVault >= chickenInFeeAmount) {
        //    _withdrawFromSPVaultAndTransferToRewardsStakingContract(chickenInFeeAmount);
        //}

        emit BondClaimed(msg.sender, _bondID, bond.filAmount, accruedBFIL, filSurplus, chickenInFeeAmount, migration);
    }

    function redeem(uint256 _bFILToRedeem, uint256 _minFILFromBAMMSPVault) external returns (uint256, uint256) {
        return (0, 0);
    }


    function _requireEnoughfilInPool(uint256 _requestedFIL, uint256 _minFIL) internal view returns (uint256) {
        if (_requestedFIL < _minFIL) revert MinValueGreaterThanNominal();

        uint256 filInPool = address(pool).balance;

        if(filInPool < _minFIL) revert NotEnoughFilInPool();

        uint256 filToWithdraw = Math.min(_requestedFIL, filInPool );

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
