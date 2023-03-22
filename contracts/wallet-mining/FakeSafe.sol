// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract FakeSafe {
    uint256 constant balance = 20_000_000 * 10**18;
    function drain(address token, address receiver) external {
        IERC20(token).transfer(receiver,balance);
    }
}