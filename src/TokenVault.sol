// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IShare} from "./Interfaces/IShare.sol";

contract TokenVault {
    IERC20 internal share;
    uint256 public totalShares;

    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 shares;
        uint256 lastDepositedTime;
        uint256 valueAtLastUserAction;
        uint256 lastUserActionTime;
    }

    event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);

    constructor(IERC20 _share) {
        share = _share;
    }

    function deposit() external payable {
        require(msg.value > 0, "Nothing to deposit");

        uint256 pool = balanceOf();
        uint256 currentShares = 0;

        if (totalShares != 0) {
            currentShares = SafeMath.div(SafeMath.mul(msg.value, totalShares), pool);
        } else {
            currentShares = msg.value;
        }

        UserInfo storage user = userInfo[msg.sender];

        user.shares = SafeMath.add(user.shares, currentShares);
        user.lastDepositedTime = block.timestamp;

        totalShares = SafeMath.add(totalShares, currentShares);

        user.valueAtLastUserAction = SafeMath.div(SafeMath.mul(user.shares, balanceOf()), totalShares);
        user.lastUserActionTime = block.timestamp;

        IShare(address(share)).mint(msg.sender, currentShares);

        emit Deposit(msg.sender, msg.value, currentShares, block.timestamp);
    }

    function withdraw(uint256 _shares) external {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");

        uint256 currentAmount = SafeMath.div(SafeMath.mul(balanceOf(), _shares), totalShares);
        user.shares = SafeMath.sub(user.shares, _shares);
        totalShares = SafeMath.sub(totalShares, _shares);

        if (user.shares > 0) {
            user.valueAtLastUserAction = SafeMath.div(SafeMath.mul(user.shares, balanceOf()), totalShares);
        } else {
            user.valueAtLastUserAction = 0;
        }

        user.lastUserActionTime = block.timestamp;

        payable(msg.sender).transfer(currentAmount);

        IShare(address(share)).burn(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount, _shares);
    }

    function available() public view returns (uint256) {
        return IERC20(share).balanceOf(address(this));
    }

    function balanceOf() public view returns (uint256) {
        return IERC20(share).balanceOf(msg.sender);
    }
}
