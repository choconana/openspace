// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./IDex.sol";
import "../uniswapV2/periphery/interfaces/IUniswapV2Router02.sol";
import "../uniswapV2/periphery/interfaces/IWETH.sol";
import "../uniswapV2/periphery/interfaces/IERC20.sol";

contract MyDex is IDex {

    IWETH public weth;

    IUniswapV2Router02 public router;

    constructor(address _router) {
        router = IUniswapV2Router02(_router);
        weth = IWETH(router.WETH());
    }

    function sellETH(address buyToken,uint256 minBuyAmount) external payable {
        address seller = msg.sender;
        uint256 amountIn = msg.value;
        require(amountIn > 0, "invalid amount");

        // 1. get token amount from swap
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = buyToken;
        uint[] memory amounts = router.swapExactETHForTokens{value: amountIn}(minBuyAmount, path, seller, block.timestamp);

        emit Sell(buyToken, amounts[1]);
    }

    function buyETH(address sellToken,uint256 sellAmount,uint256 minBuyAmount) external {

        // 1. transfer RNT to DEX
        IERC20(sellToken).transferFrom(msg.sender, address(this), sellAmount);

        // 2. DEX approve RNT to router, then router could exchange RNT for WETH
        if (IERC20(sellToken).allowance(address(this), address(router)) < sellAmount) {
            // approve max uint256 one time, won't approve frequently
            IERC20(sellToken).approve(address(router), type(uint256).max);
        }
        address[] memory path = new address[](2);
        path[0] = sellToken;
        path[1] = address(weth);
        uint[] memory amounts = router.swapExactTokensForETH(sellAmount, minBuyAmount, path, msg.sender, block.timestamp);

        emit Buy(sellToken, sellAmount, amounts[1]);
    }

}