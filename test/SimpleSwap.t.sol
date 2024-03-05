//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma abicoder v2;

import { Test, console2 } from "forge-std/Test.sol";
import {BaseDeploy} from "./BaseDeploy.t.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract SimpleFlash is BaseDeploy {
    uint MINIMUM_LIQUIDITY = 10**3;
    
    address internal defaultSender = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    
    function test_fuzz_mini_AddLiquidity(uint256 amount0) public { 
        vm.assume(amount0 > 0 && amount0 < type(uint256).max/1000 && 1002 / Math.sqrt(amount0) > 0);

        uint256 amount1 = (uint256(2000**2) / amount0);
        uint liquidity = Math.sqrt(amount0*(amount1)) - (MINIMUM_LIQUIDITY);

        vm.startPrank(deployer);
        IERC20(USDB).approve(address(swapRouter), type(uint256).max);
        if(liquidity < 0){
            vm.expectRevert();
            (uint amountA, uint amountB, ) = addLiquidity(USDB, tokens[0], amount0, amount1);
        }
        
        vm.stopPrank();
    }

    function test_SwapUSDBtoETHtoRETH9() public {
        vm.startBroadcast(deployer);

        IERC20(USDB).approve(address(swapRouter), type(uint256).max);
        IERC20(RETH9).approve(address(swapRouter), type(uint256).max);
        (uint amountA1, uint amountB1, uint liquidity1) = addLiquidity(USDB, RETH9, 10000, 100000);
        console2.log("First addLiquidity USDB/RETH9(usd-eth-lp)", amountA1, amountB1, liquidity1);

        (uint amountA2, uint amountB2, uint liquidity2) = addLiquidity(tokens[0], RETH9, 10000, 1000);
        console2.log("Second addLiquidity tokens[0]/RETH9(t0-eth-lp)", amountA2, amountB2, liquidity2);

        IERC20(USDB).transfer(address(this), 1000);
        uint256[] memory amounts = swapToken(deployer, USDB, tokens[0], 1000, 0, block.timestamp);
        console2.log("Swap USDB to RETH9:", amounts[0], "-", amounts[2]);

        vm.stopBroadcast();
    }

    function swapToken(address from, address tokenIn,address tokenOut, uint256 amountIn, uint256 amountOutMin, uint256 deadline) internal returns(uint256[] memory){
        // IERC20(tokenIn).transferFrom(from, address(this), amountIn);
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        address[] memory path;
        uint256[] memory amounts;
        if (tokenIn == RETH9) {
            path = new address[](2);
            path[0] = RETH9;
            path[1] = tokenOut;
            amounts = swapRouter.swapExactETHForTokens{value: amountIn}(
                amountOutMin,
                path,
                address(this),
                deadline
            );
        } 
        else if(tokenOut == RETH9){
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = RETH9;
            amounts = swapRouter.swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                address(this),
                deadline
            );
        }
        else {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = RETH9;
            path[2] = tokenOut;
            amounts = swapRouter.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                deadline
            ); 
        }
        return amounts;
    }

}