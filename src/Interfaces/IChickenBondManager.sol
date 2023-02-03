// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;


interface IChickenBondManager {

    event BondCreated(address indexed bonder, uint256 bondId, uint256 amount);

    event BondClaimed(
        address indexed bonder,
        uint256 bondId,
        uint256 filAmount,
        uint256 bfilAmount,
        uint256 filSurplus,
        uint256 chickenInFeeAmount,
        bool migration
    );


    event BondCancelled(address indexed bonder, uint256 bondId, uint256 principalfilAmount, uint256 minfilAmount, uint256 withdrawnfilAmount);

    event BFILRedeemed(address indexed redeemer, uint256 bfilAmount, uint256 minfilAmount, uint256 filAmount, uint256 yTokens, uint256 redemptionFee);

    enum BondStatus {
        nonExistent,
        active,
        chickenedOut,
        chickenedIn
    }

    struct BondData {
        uint256 filAmount;
        uint64 claimedBFIL; // In BFIL units without decimals
        uint64 startTime;
        uint64 endTime; // Timestamp of chicken in/out event
        BondStatus status;
    }


    function createBond() external payable returns (uint256);
    function chickenOut(uint256 _bondID, uint256 _minFIL) external;
    function chickenIn(uint256 _bondID) external;
    function redeem(uint256 _bFILToRedeem, uint256 _minFILFromBAMMSPVault) external returns (uint256, uint256);

    // getters
    //function calcRedemptionFeePercentage(uint256 _fractionOfBFILToRedeem) external view returns (uint256);
    //function getBondData(uint256 _bondID) external view returns (uint256 filAmount, uint64 claimedBFIL, uint64 startTime, uint64 endTime, uint8 status);
    //function getFILToAcquire(uint256 _bondID) external view returns (uint256);
    //function calcAccruedBFIL(uint256 _bondID) external view returns (uint256);
    //function calcBondBFILCap(uint256 _bondID) external view returns (uint256);
    //function calcTotalFILValue() external view returns (uint256);
    //function getPendingFIL() external view returns (uint256);
    //function getAcquiredFILInSP() external view returns (uint256);
    //function getTotalAcquiredFIL() external view returns (uint256);
    //function getPermanentFIL() external view returns (uint256);
    //function getOwnedFILInSP() external view returns (uint256);
    //function calcSystemBackingRatio() external view returns (uint256);
    //function calcUpdatedAccrualParameter() external view returns (uint256);
}
