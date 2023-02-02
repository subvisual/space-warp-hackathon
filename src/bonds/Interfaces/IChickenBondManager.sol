// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

interface IChickenBondManager {
    // Valid values for `status` returned by `getBondData()`
    enum BondStatus {
        nonExistent,
        active,
        chickenedOut,
        chickenedIn
    }

    function createBond(uint256 _lusdAmount) external returns (uint256);
    function chickenOut(uint256 _bondID, uint256 _minFIL) external;
    function chickenIn(uint256 _bondID) external;
    function redeem(uint256 _bFILToRedeem, uint256 _minFILFromBAMMSPVault) external returns (uint256, uint256);

    // getters
    //function calcRedemptionFeePercentage(uint256 _fractionOfBFILToRedeem) external view returns (uint256);
    //function getBondData(uint256 _bondID) external view returns (uint256 lusdAmount, uint64 claimedBFIL, uint64 startTime, uint64 endTime, uint8 status);
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
