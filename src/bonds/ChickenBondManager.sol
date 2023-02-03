// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IBondNFT.sol";
import "./Interfaces/IBFIL.sol";

// import "forge-std/console.sol";


contract ChickenBondManager is IChickenBondManager {

    IBondNFT immutable public bondNFT;
    uint256 public immutable MIN_BOND_AMOUNT;             // Minimum amount of LUSD that needs to be bonded
    uint256 public totalWeightedStartTimes; // Sum of `lusdAmount * startTime` for all outstanding bonds (used to tell weighted average bond age)
    mapping (uint256 => BondData) private idToBondData;
    uint256 private pendingLUSD;          // Total pending LUSD. It will always be in SP (B.Protocol)


    constructor(address _bondNFT, uint256 _MIN_BOND_AMOUNT ) {
        bondNFT = IBondNFT(_bondNFT);
        MIN_BOND_AMOUNT = _MIN_BOND_AMOUNT ;
    }

    function createBond() external payable returns (uint256){
        if (msg.value < MIN_BOND_AMOUNT ) revert BondAmountNotMet();

        //_updateAccrualParameter();

        // Mint the bond NFT to the caller and get the bond ID
        uint256 bondID = bondNFT.mint(msg.sender);

        //Record the user’s bond data: bond_amount and start_time
        BondData memory bondData;
        bondData.lusdAmount = msg.value ;
        bondData.startTime = uint64(block.timestamp);
        bondData.status = BondStatus.active;
        idToBondData[bondID] = bondData;

        pendingLUSD += msg.value;
        totalWeightedStartTimes += msg.value * block.timestamp;


        // Deposit the LUSD to the B.Protocol LUSD vault
        //_depositToBAMM(_lusdAmount);
        //TODO deposit to pool 
        // pool.deposit(_lusdAmount);

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
        //uint80 newDna = bondNFT.setFinalExtraData(msg.sender, _bondID, permanentLUSD / NFT_RANDOMNESS_DIVISOR);

        //countChickenOut += 1;

        //pendingLUSD -= bond.lusdAmount;
        //totalWeightedStartTimes -= bond.lusdAmount * bond.startTime;

        ///* In practice, there could be edge cases where the pendingLUSD is not fully backed:
        //* - Heavy liquidations, and before yield has been converted
        //* - Heavy loss-making liquidations, i.e. at <100% CR
        //* - SP or B.Protocol vault hack that drains LUSD
        //*
        //* The user can decide how to handle chickenOuts if/when the recorded pendingLUSD is not fully backed by actual
        //* LUSD in B.Protocol / the SP, by adjusting _minLUSD */
        //uint256 lusdToWithdraw = _requireEnoughLUSDInBAMM(bond.lusdAmount, _minLUSD);

        //// Withdraw from B.Protocol LUSD vault
        //_withdrawFromBAMM(lusdToWithdraw, msg.sender);

        //emit BondCancelled(msg.sender, _bondID, bond.lusdAmount, _minLUSD, lusdToWithdraw);
    }

        function chickenIn(uint256 _bondID) external{
        }

        //BondData memory bond = idToBondData[_bondID];

        //_requireCallerOwnsBond(_bondID);
        //_requireActiveStatus(bond.status);

        //uint256 updatedAccrualParameter = _updateAccrualParameter();
        //(uint256 bammLUSDValue, uint256 lusdInBAMMSPVault) = _updateBAMMDebt();

        //(uint256 chickenInFeeAmount, uint256 bondAmountMinusChickenInFee) = _getBondWithChickenInFeeApplied(bond.lusdAmount);

        ///* Upon the first chicken-in after a) system deployment or b) redemption of the full bLUSD supply, divert
        //* any earned yield to the bLUSD-LUSD AMM for fairness.
        //*
        //* This is not done in migration mode since there is no need to send rewards to the staking contract.
        //*/
        //if (bLUSDToken.totalSupply() == 0 && !migration) {
        //    lusdInBAMMSPVault = _firstChickenIn(bond.startTime, bammLUSDValue, lusdInBAMMSPVault);
        //}

        //// Get the LUSD amount to acquire from the bond in proportion to the system's current backing ratio, in order to maintain said ratio.
        //uint256 lusdToAcquire = _calcAccruedAmount(bond.startTime, bondAmountMinusChickenInFee, updatedAccrualParameter);
        //// Get backing ratio and accrued bLUSD
        //uint256 backingRatio = _calcSystemBackingRatioFromBAMMValue(bammLUSDValue);
        //uint256 accruedBLUSD = lusdToAcquire * 1e18 / backingRatio;

        //idToBondData[_bondID].claimedBLUSD = uint64(Math.min(accruedBLUSD / 1e18, type(uint64).max)); // to units and uint64
        //idToBondData[_bondID].status = BondStatus.chickenedIn;
        //idToBondData[_bondID].endTime = uint64(block.timestamp);
        //uint80 newDna = bondNFT.setFinalExtraData(msg.sender, _bondID, permanentLUSD / NFT_RANDOMNESS_DIVISOR);

        //countChickenIn += 1;

        //// Subtract the bonded amount from the total pending LUSD (and implicitly increase the total acquired LUSD)
        //pendingLUSD -= bond.lusdAmount;
        //totalWeightedStartTimes -= bond.lusdAmount * bond.startTime;

        //// Get the remaining surplus from the LUSD amount to acquire from the bond
        //uint256 lusdSurplus = bondAmountMinusChickenInFee - lusdToAcquire;

        //// Handle the surplus LUSD from the chicken-in:
        //if (!migration) { // In normal mode, add the surplus to the permanent bucket by increasing the permament tracker. This implicitly decreases the acquired LUSD.
        //    permanentLUSD += lusdSurplus;
        //} else { // In migration mode, withdraw surplus from B.Protocol and refund to bonder
        //    // TODO: should we allow to pass in a minimum value here too?
        //    (,lusdInBAMMSPVault,) = bammSPVault.getLUSDValue();
        //    uint256 lusdToRefund = Math.min(lusdSurplus, lusdInBAMMSPVault);
        //    if (lusdToRefund > 0) { _withdrawFromBAMM(lusdToRefund, msg.sender); }
        //}

        //bLUSDToken.mint(msg.sender, accruedBLUSD);

        //// Transfer the chicken in fee to the LUSD/bLUSD AMM LP Rewards staking contract during normal mode.
        //if (!migration && lusdInBAMMSPVault >= chickenInFeeAmount) {
        //    _withdrawFromSPVaultAndTransferToRewardsStakingContract(chickenInFeeAmount);
        //}

        //emit BondClaimed(msg.sender, _bondID, bond.lusdAmount, accruedBLUSD, lusdSurplus, chickenInFeeAmount, migration, newDna);
        //}
    function redeem(uint256 _bFILToRedeem, uint256 _minFILFromBAMMSPVault) external returns (uint256, uint256){
        return (0,0);

    }
}
