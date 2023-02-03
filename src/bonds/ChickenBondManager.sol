// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Interfaces/IBondNFT.sol";
import "../Interfaces/IBFIL.sol";
import "../Interfaces/IPool.sol";

// import "forge-std/console.sol";

error BondAmountNotMet();

contract ChickenBondManager is IChickenBondManager {

    IPool immutable public pool;
    IBondNFT immutable public bondNFT;
    uint256 public immutable MIN_BOND_AMOUNT;             // Minimum amount of fil that needs to be bonded
    uint256 public totalWeightedStartTimes; // Sum of `filAmount * startTime` for all outstanding bonds (used to tell weighted average bond age)
    mapping (uint256 => BondData) private idToBondData;
    uint256 private pendingfil;          // Total pending fil. It will always be in SP (B.Protocol)
    uint256 private permanentfil;          // Total pending fil. It will always be in SP (B.Protocol)


    constructor(address _bondNFT, address _pool, uint256 _MIN_BOND_AMOUNT ) {
        bondNFT = IBondNFT(_bondNFT);
        pool = IPool(_pool);
        MIN_BOND_AMOUNT = _MIN_BOND_AMOUNT ;
    }

    function createBond() external payable returns (uint256){
        if (msg.value < MIN_BOND_AMOUNT ) revert BondAmountNotMet();

        //_updateAccrualParameter();

        // Mint the bond NFT to the caller and get the bond ID
        uint256 bondID = bondNFT.mint(msg.sender);

        //Record the user’s bond data: bond_amount and start_time
        BondData memory bondData;
        bondData.filAmount = msg.value ;
        bondData.startTime = uint64(block.timestamp);
        bondData.status = BondStatus.active;
        idToBondData[bondID] = bondData;

        pendingfil += msg.value;
        totalWeightedStartTimes += msg.value * block.timestamp;


        // Deposit the fil to the B.Protocol fil vault
        //_depositToBAMM(_filAmount);
        //TODO deposit to pool 
        pool.depositLender{value: msg.value}();

        emit BondCreated(msg.sender, bondID, msg.value);

        return bondID;
    }

    function chickenOut(uint256 _bondID, uint256 _minFIL) external{
        //BondData memory bond = idToBondData[_bondID];

        //if (msg.sender != bondNFT.ownerOf(_bondID), "CBM: Caller must own the bond");

        //if(status != BondStatus.active, "CBM: Bond must be active");

        ////_updateAccrualParameter();

        //idToBondData[_bondID].status = BondStatus.chickenedOut;
        //idToBondData[_bondID].endTime = uint64(block.timestamp);
        //uint80 newDna = bondNFT.setFinalExtraData(msg.sender, _bondID, permanentfil / NFT_RANDOMNESS_DIVISOR);

        //countChickenOut += 1;

        //pendingfil -= bond.filAmount;
        //totalWeightedStartTimes -= bond.filAmount * bond.startTime;

        ///* In practice, there could be edge cases where the pendingfil is not fully backed:
        //* - Heavy liquidations, and before yield has been converted
        //* - Heavy loss-making liquidations, i.e. at <100% CR
        //* - SP or B.Protocol vault hack that drains fil
        //*
        //* The user can decide how to handle chickenOuts if/when the recorded pendingfil is not fully backed by actual
        //* fil in B.Protocol / the SP, by adjusting _minfil */
        //uint256 filToWithdraw = _requireEnoughfilInBAMM(bond.filAmount, _minfil);

        //// Withdraw from B.Protocol fil vault
        //_withdrawFromBAMM(filToWithdraw, msg.sender);

        //emit BondCancelled(msg.sender, _bondID, bond.filAmount, _minfil, filToWithdraw);
    }

        function chickenIn(uint256 _bondID) external{
        }

        //BondData memory bond = idToBondData[_bondID];

        //_requireCallerOwnsBond(_bondID);
        //_requireActiveStatus(bond.status);

        //uint256 updatedAccrualParameter = _updateAccrualParameter();
        //(uint256 bammfilValue, uint256 filInBAMMSPVault) = _updateBAMMDebt();

        //(uint256 chickenInFeeAmount, uint256 bondAmountMinusChickenInFee) = _getBondWithChickenInFeeApplied(bond.filAmount);

        ///* Upon the first chicken-in after a) system deployment or b) redemption of the full bfil supply, divert
        //* any earned yield to the bfil-fil AMM for fairness.
        //*
        //* This is not done in migration mode since there is no need to send rewards to the staking contract.
        //*/
        //if (bfilToken.totalSupply() == 0 && !migration) {
        //    filInBAMMSPVault = _firstChickenIn(bond.startTime, bammfilValue, filInBAMMSPVault);
        //}

        //// Get the fil amount to acquire from the bond in proportion to the system's current backing ratio, in order to maintain said ratio.
        //uint256 filToAcquire = _calcAccruedAmount(bond.startTime, bondAmountMinusChickenInFee, updatedAccrualParameter);
        //// Get backing ratio and accrued bfil
        //uint256 backingRatio = _calcSystemBackingRatioFromBAMMValue(bammfilValue);
        //uint256 accruedBFIL = filToAcquire * 1e18 / backingRatio;

        //idToBondData[_bondID].claimedBFIL = uint64(Math.min(accruedBFIL / 1e18, type(uint64).max)); // to units and uint64
        //idToBondData[_bondID].status = BondStatus.chickenedIn;
        //idToBondData[_bondID].endTime = uint64(block.timestamp);
        //uint80 newDna = bondNFT.setFinalExtraData(msg.sender, _bondID, permanentfil / NFT_RANDOMNESS_DIVISOR);

        //countChickenIn += 1;

        //// Subtract the bonded amount from the total pending fil (and implicitly increase the total acquired fil)
        //pendingfil -= bond.filAmount;
        //totalWeightedStartTimes -= bond.filAmount * bond.startTime;

        //// Get the remaining surplus from the fil amount to acquire from the bond
        //uint256 filSurplus = bondAmountMinusChickenInFee - filToAcquire;

        //// Handle the surplus fil from the chicken-in:
        //if (!migration) { // In normal mode, add the surplus to the permanent bucket by increasing the permament tracker. This implicitly decreases the acquired fil.
        //    permanentfil += filSurplus;
        //} else { // In migration mode, withdraw surplus from B.Protocol and refund to bonder
        //    // TODO: should we allow to pass in a minimum value here too?
        //    (,filInBAMMSPVault,) = bammSPVault.getfilValue();
        //    uint256 filToRefund = Math.min(filSurplus, filInBAMMSPVault);
        //    if (filToRefund > 0) { _withdrawFromBAMM(filToRefund, msg.sender); }
        //}

        //bfilToken.mint(msg.sender, accruedBFIL);

        //// Transfer the chicken in fee to the fil/bfil AMM LP Rewards staking contract during normal mode.
        //if (!migration && filInBAMMSPVault >= chickenInFeeAmount) {
        //    _withdrawFromSPVaultAndTransferToRewardsStakingContract(chickenInFeeAmount);
        //}

        //emit BondClaimed(msg.sender, _bondID, bond.filAmount, accruedBFIL, filSurplus, chickenInFeeAmount, migration, newDna);
        //}
    function redeem(uint256 _bFILToRedeem, uint256 _minFILFromBAMMSPVault) external returns (uint256, uint256){
        return (0,0);

    }

    // Bond getters

    function getBondData(uint256 _bondID)
        external
        view
        returns (
            uint256 filAmount,
            uint64 claimedBFIL,
            uint64 startTime,
            uint64 endTime,
            uint8 status
        )
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
