//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import { Test, console2 } from "forge-std/Test.sol";
import {BaseDeploy} from "./BaseDeploy.t.sol";
import "src/libraries/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "src/libraries/SafeMath.sol";

contract SimpleFlash is BaseDeploy {
    IERC20 NBT = IERC20(0x5FbDB2315678afecb367f032d93F642f64180aa3);
    uint MINIMUM_LIQUIDITY = 10**3;

    using SafeMath for uint;

    function setUp() public override {
        super.setUp();
    }

    function test_LiquidityETH(uint256 amount) public {
        vm.startPrank(deployer);
        NBT.approve(address(swapRouter), 2000);
        swapRouter.addLiquidityETH{value: 2000}(
            address(NBT),
            2000,
            0,
            0,
            deployer,
            block.timestamp + 1 days
        );
    }
    
    function test_fuzz_amount_AddLiquidity(uint256 amount0) public { 
        vm.assume(amount0 > 0 && amount0 < type(uint256).max/1000 && 1002 / Math.sqrt(amount0) > 0);

        uint256 amount1 = (uint256(2000**2) / amount0);
        uint liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);

        vm.startPrank(deployer);
        NBT.approve(address(swapRouter), type(uint256).max);
        if(liquidity < 0){
            vm.expectRevert();
            (uint amountA, uint amountB, uint liquidity) = addLiquidity(address(NBT), tokens[0], amount0, amount1);
        }
        
        vm.stopPrank();
    }

    function swapToken(address tokenIn,address tokenOut, uint256 amountIn, uint256 amountOutMin, uint256 deadline) internal returns(uint256[] memory amounts){
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        address[] memory path;
        if (tokenIn == WETH9) {
            path = new address[](2);
            path[0] = WETH9;
            path[1] = tokenOut;
            swapRouter.swapExactETHForTokens{value: amountIn}(
                amountOutMin,
                path,
                address(this),
                deadline
            );
        } 
        else if(tokenOut == WETH9){
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = WETH9;
            swapRouter.swapExactTokensForETH(
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
            path[1] = WETH9;
            path[2] = tokenOut;
            swapRouter.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                deadline
            ); 
        }
    }

}