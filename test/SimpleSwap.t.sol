//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma abicoder v2;

import {Test, console2} from "forge-std/Test.sol";
import {BaseDeploy} from "./BaseDeploy.t.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleSwap is BaseDeploy {
    uint256 MINIMUM_LIQUIDITY = 10 ** 3;

    address internal defaultSender = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    function setUp() public override {
        super.setUp();

        vm.startBroadcast(deployer);

        // 提供 USDB/ETH tokens[0]-ETH pair
        IERC20(USDB).approve(address(swapRouter), type(uint256).max);
        IERC20(RETH9).approve(address(swapRouter), type(uint256).max);
        (uint256 amountA1, uint256 amountB1, uint256 liquidity1) = addLiquidity(USDB, RETH9, 10000, 100000);
        (uint256 amountA2, uint256 amountB2, uint256 liquidity2) = addLiquidity(tokens[0], RETH9, 10000, 1000);

        vm.stopBroadcast();
    }

    function test_SwapUSDBtoETHtoRETH9() public {
        vm.startBroadcast(deployer);

        uint256 amountUSDB = 10000;
        IERC20(USDB).transfer(address(this), amountUSDB);

        console2.log("----------------- start test USDB to ETH to token0 ---------------");
        uint256[] memory amounts = swapToken(deployer, USDB, tokens[0], amountUSDB / 10, 0, block.timestamp);
        console2.log("Swap USDB to RETH9:", amounts[0], "-", amounts[2]);

        console2.log("----------------------- start test USDB to ETH ------------------");
        amounts = swapToken(deployer, USDB, RETH9, amountUSDB / 10, 0, block.timestamp);
        console2.log("Swap USDB to ETH:", amounts[0], "-", amounts[1]);

        console2.log("----------------------- start test ETH to token0 ------------------");
        amounts = swapToken(deployer, RETH9, USDB, amountUSDB / 10, 0, block.timestamp);
        console2.log("Swap USDB to ETH:", amounts[0], "-", amounts[1]);

        vm.stopBroadcast();
    }

    function swapToken(
        address from,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) internal returns (uint256[] memory) {
        // IERC20(tokenIn).transferFrom(from, address(this), amountIn);
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        address[] memory path;
        uint256[] memory amounts;
        if (tokenIn == RETH9) {
            path = new address[](2);
            path[0] = RETH9;
            path[1] = tokenOut;
            amounts = swapRouter.swapExactETHForTokens{value: amountIn}(amountOutMin, path, from, deadline);
        } else if (tokenOut == RETH9) {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = RETH9;
            amounts = swapRouter.swapExactTokensForETH(amountIn, amountOutMin, path, from, deadline);
        } else {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = RETH9;
            path[2] = tokenOut;
            amounts = swapRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, from, deadline);
        }
        return amounts;
    }
}
