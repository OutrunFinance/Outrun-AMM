//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma abicoder v2;

import {BaseDeploy, factoryAtricle, routerAtricle} from "./BaseDeploy.t.sol";
import {console2} from "forge-std/console2.sol";

import 'src/libraries/OutswapV1Library.sol';
import "@openzeppelin/contracts/utils/math/Math.sol";

import {IOutswapV1Factory} from "src/core/interfaces/IOutswapV1Factory.sol";
import {IOutswapV1Pair} from "src/core/interfaces/IOutswapV1Pair.sol";
import {IOutswapV1Router} from "src/router/interfaces/IOutswapV1Router.sol";
import {IOutswapV1Callee} from "src/core/interfaces/IOutswapV1Callee.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* 
    This contract is used to test the flashloan functionality of the Outswap V1 protocol.
    flash Swap is a strategy to profit from the price differences between different exchanges or liquidity pools. 
    1. Creating two factory contracts, 

    2. Creating  two different liquidity pools, each for different trading pairs. 
      --> Pool1 for token1/token2 = 1000/1000 and the other for token1/token2 = 100/1000.
 */

contract SimpleFlash is IOutswapV1Callee {
    event Repay(address tokenBorrow, uint RepayAmount);
    
    address private immutable owner;

    constructor() {
        owner = msg.sender;
    }

    // 借t1
    function flashSwap(address tokenBorrow, address tokenRevenue, address router1, address router2, uint256 borrowAmount)
        external
    {
        require(tokenBorrow != address(0) && tokenRevenue != address(0), "Flash: ZERO_ADDRESS");
        require(router1 != address(0) && router2 != address(0), "Flash: ZERO_ADDRESS");

        address[] memory path = new address[](2);
        (path[0], path[1]) = tokenBorrow < tokenRevenue ? (tokenBorrow, tokenRevenue) : (tokenRevenue, tokenBorrow);
        (uint256 amount0Out, uint256 amount1Out) =
            tokenBorrow < tokenRevenue ? (borrowAmount, uint256(0)) : (uint256(0), borrowAmount);

        address pair = IOutswapV1Factory(IOutswapV1Router(router1).factory()).getPair(path[0], path[1]);
        IOutswapV1Pair(pair).swap(
            amount0Out, amount1Out, address(this), abi.encode(msg.sender, path, tokenBorrow, tokenRevenue, router1, router2, borrowAmount)
        );
    }

    // This function is called by the token0/token1(1:1) pair1 contract
    function OutswapV1Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        (
            address caller,
            address[] memory path,
            address tokenBorrow,
            address tokenRevenue,
            address router1,
            address router2,
            uint256 borrowAmount
        ) = abi.decode(data, (address, address[], address, address, address, address, uint256));

        address pair1 = IOutswapV1Factory(IOutswapV1Router(router1).factory()).getPair(path[0], path[1]);
        require(msg.sender == pair1, "KittyTradeX FlashLoan: not pair");

        require(sender == address(this), "KittyTradeX FlashLoan: not sender");
        require(amount0 == borrowAmount || amount1 == borrowAmount, "KittyTradeX FlashLoan: amount != borrowAmount");

        /* perform 逻辑：将借出来的t1还给pool1 */
        address[] memory swapPath = new address[](2);
        (swapPath[0], swapPath[1]) = (tokenBorrow, tokenRevenue);
        IERC20(swapPath[0]).approve(router2, type(uint256).max);
        // IERC20(swapPath[1]).approve(router2, type(uint256).max);
        IOutswapV1Router(router2).swapExactTokensForTokens(borrowAmount, 10, swapPath, address(this), block.timestamp);

        // 还t1
        (swapPath[0], swapPath[1]) = (tokenRevenue, tokenBorrow);
        uint256[] memory amounts = OutswapV1Library.getAmountsIn(IOutswapV1Router(router1).factory(), borrowAmount, swapPath);
        IERC20(tokenRevenue).transfer(pair1, amounts[0]);
        emit Repay(tokenRevenue, amounts[0]);
    }
}

contract FlashMock is BaseDeploy {
    uint256 MINIMUM_LIQUIDITY = 10 ** 3;

    address internal router2;

    address internal defaultSender = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    function setUp() public override {
        super.setUp();

        vm.startBroadcast(deployer);

        uint amount = 10000;

        console2.log("Factory contracts created successfully.");
        address factory2 = deployCode(factoryAtricle, abi.encode(deployer));
        router2 = deployCode(routerAtricle, abi.encode(factory2, RETH9, RUSD9, USDB));

        (uint256 amountA1, uint256 amountB1, uint256 liquidity1) = addLiquidity(tokens[0], tokens[1], amount, amount); // token0 = token1
        console2.log("Creating liquidity pool1", amount, ":", amount);

        safeApprove(tokens[0], router2, type(uint256).max);
        safeApprove(tokens[1], router2, type(uint256).max);
        (uint256 amountA2, uint256 amountB2, uint256 liquidity2) = addLiquidity(router2, tokens[0], tokens[1], amount, amount*100); // token0 = 100token
        console2.log("Creating liquidity pool1", amount, ":", amount*100);

        vm.stopBroadcast();
    }

    function test_flashswap() public {
        console2.log("Starting the flash swap...");

        vm.startBroadcast(deployer);

        SimpleFlash flash = new SimpleFlash();

        uint256 amountBefore = IERC20(tokens[1]).balanceOf(address(flash));
        console2.log("flash contract's token1 balance before flanswap:", amountBefore);

        flash.flashSwap(tokens[0], tokens[1], address(swapRouter), router2, 100);

        uint256 amountAfter = IERC20(tokens[1]).balanceOf(address(flash));
        console2.log("flash contract's token1 balance after flanswap:", amountAfter);

        if(amountAfter > amountBefore) {
            console2.log("flash contract recieved profit of token1", amountAfter - amountBefore);
        }

        vm.stopBroadcast();
    }
}
