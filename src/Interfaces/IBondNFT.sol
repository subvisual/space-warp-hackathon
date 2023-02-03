// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./IChickenBondManager.sol";

interface IBondNFT {
    function mint(address bonder) external returns (uint256);
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address owner);
    function chickenBondManager() external view returns (IChickenBondManager);
    function getBondAmount(uint256 _tokenID) external view returns (uint256 amount);
    function getBondStartTime(uint256 _tokenID) external view returns (uint256 startTime);
    function getBondEndTime(uint256 _tokenID) external view returns (uint256 endTime);
    function getBondStatus(uint256 _tokenID) external view returns (uint8 status);
}
