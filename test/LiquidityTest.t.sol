//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma abicoder v2;

import { Test, console2 } from "forge-std/Test.sol";
import {BaseDeploy} from "./BaseDeploy.t.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract liquidityTest is BaseDeploy {
    uint MINIMUM_LIQUIDITY = 10**3;
    
    address internal defaultSender = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    function setUp() public override {
        super.setUp();
        
        vm.prank(deployer);
        IERC20(USDB).approve(address(swapRouter), type(uint256).max);
    }
    
    function test_fuzz_mini_AddLiquidity(uint256 amount0) public { 
        vm.assume(amount0 > 0 && amount0 < type(uint256).max/1000 && 1002 / Math.sqrt(amount0) > 0);

        uint256 amount1 = (uint256(2000**2) / amount0);
        uint liquidity = Math.sqrt(amount0*(amount1)) - (MINIMUM_LIQUIDITY);

        vm.startPrank(deployer);
        if(liquidity < 0){
            vm.expectRevert();
            (uint amountA, uint amountB, ) = addLiquidity(USDB, tokens[0], amount0, amount1);
            return;
        }
        (uint amountA, uint amountB, ) = addLiquidity(USDB, tokens[0], amount0, amount1);
        vm.stopPrank();
    }

    function testAddLiquidity() public {
        uint amount0 = 10000;
        uint amount1 = 1000;
        vm.startPrank(deployer);
        (uint amountA, uint amountB, ) = addLiquidity(USDB, tokens[0], amount0, amount1);
        vm.stopPrank();
    }

    
    function test_AddLiquidityETH() public returns (uint, uint, uint){
        // vm.assume(amount0 > 200 && amount0 < type(uint256).max/10000);
        vm.startPrank(deployer);

        uint256 amount0 = 100000;
        IERC20(tokens[0]).approve(address(swapRouter), type(uint256).max);
        (uint amountA, uint amountB, uint liquidity ) = swapRouter.addLiquidityETH{value:10000}(tokens[0], amount0,0, 0, deployer, block.timestamp + 1 days);
        // require(success, "addLiquidityETH failed");
        console2.log("Test use ETH and tokens to AddLiquidityETH: ETH 10000 - ", 'tokens[0]', amount0);
        console2.log("using ETH", amountB, "to add", liquidity);
        
        vm.stopPrank();

        return (amountA, amountB, liquidity);
    }

    function test_TwoAddLiquidity() public {
        test_AddLiquidityETH();
        test_AddLiquidityETH();
    }

    function test_fuzz_removeLiquidityETH(uint amountLp) public {
        vm.assume(amountLp > 10); // 保证了lp 提款的最小值 - 这个测试是4
        (uint amountA, uint amountB, uint liquidity ) = test_AddLiquidityETH();

        vm.startPrank(deployer);

        (address tokenA, address tokenB) = (tokens[0], RETH9);
        address pair = poolFactory.getPair(tokenA, tokenB);
        IERC20(pair).approve(address(swapRouter), type(uint256).max);

        if(amountLp > liquidity){
            vm.expectRevert();
            (uint256 amountToken, uint256 amountETH) = swapRouter.removeLiquidityETH(tokens[0], amountLp, 0, 0, deployer, block.timestamp + 1 days);
            return ;
        }
        (uint256 amountToken, uint256 amountETH) = swapRouter.removeLiquidityETH(tokens[0], amountLp, 0, 0, deployer, block.timestamp + 1 days);

        vm.stopPrank();
    }

    function test_removeLiquidityETHSupportingFeeOnTransferTokens() public {
        (uint amountA, uint amountB, uint liquidity ) = test_AddLiquidityETH();

        vm.startPrank(deployer);

        (address tokenA, address tokenB) = (tokens[0], RETH9);
        address pair = poolFactory.getPair(tokenA, tokenB);
        IERC20(pair).approve(address(swapRouter), type(uint256).max);

        if(poolFactory.feeTo() == address(0)){
            uint256 amountETH = swapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(tokens[0], liquidity/2 , 0, 0, deployer, block.timestamp + 1 days);
            poolFactory.setFeeTo(deployer);
            amountETH = swapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(tokens[0], liquidity/2 , 0, 0, deployer, block.timestamp + 1 days);
            console2.log("removeLiquidityETHSupportingFeeOnTransferTokens = removeLiquidityETH.");
        }

        vm.stopPrank();
    }
}