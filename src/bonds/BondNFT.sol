// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {ERC721} from "@solmate/tokens/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {IChickenBondManager} from "../Interfaces/IChickenBondManager.sol";

error TokenDoesNotExist();

contract BondNFT is ERC721, Ownable {
    using Strings for uint256;

    uint256 public totalSupply = 0;
    string public bondURI;
    string public chickenInURI;
    string public chickenOutURI;

    address public chickenBondManagerAddress;

    error CallerNotChickenManager();

    constructor(string memory _name, string memory _symbol, string[3] memory _URI) ERC721(_name, _symbol) {
        bondURI = _URI[0];
        chickenInURI = _URI[1];
        chickenOutURI  = _URI[2];
    }

    //
    // onlyChickenBondManager
    //
    function mint(address bonder) external returns (uint256) {
        _requireCallerIsChickenBondsManager();
        unchecked {
            uint256 tokenId = totalSupply + 1;
            _mint(bonder, tokenId);
            totalSupply++;
            return tokenId;
        }
    }

    function burn(uint256 tokenId) external {
        _requireCallerIsChickenBondsManager();
        unchecked {
            _burn(tokenId);
        }
    }

    //
    // onlyOwner
    //
    function setAddresses(address _chickenBondManagerAddress) external onlyOwner {
        chickenBondManagerAddress = _chickenBondManagerAddress;
        renounceOwnership();
    }

    //
    // view
    //

    //function chickenBondManager() external view returns (IChickenBondManager);
    //function getBondAmount(uint256 _tokenID) external view returns (uint256 amount);
    //function getBondStartTime(uint256 _tokenID) external view returns (uint256 startTime);
    //function getBondEndTime(uint256 _tokenID) external view returns (uint256 endTime);

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert TokenDoesNotExist();
        }

        IChickenBondManager chickenBondManager = IChickenBondManager(chickenBondManagerAddress);
        (,,,,uint8 status) = chickenBondManager.getBondData(tokenId);

        string memory baseURI = status == 1 ? 
            bondURI : 
            status == 2 ? 
                chickenOutURI : chickenInURI ;

        return  string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _requireCallerIsChickenBondsManager() internal view {
        if (msg.sender != chickenBondManagerAddress) revert CallerNotChickenManager();
    }
}
