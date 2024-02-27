//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import { Test, console2 } from "forge-std/Test.sol";
import { Script, console2} from "forge-std/Script.sol";
import { OutswapV1Router } from "src/router/OutswapV1Router.sol";
import { OutswapV1Factory} from "src/core/OutswapV1Factory.sol";

import {TestERC20} from "./utils/TestERC20.sol";
import {WETH} from "./utils/WETH.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "forge-std/StdUtils.sol";



contract BaseDeploy is Script {
	address public deployer = vm.envAddress("LOCAL_DEPLOYER");

	OutswapV1Factory internal poolFactory;
	OutswapV1Router internal swapRouter;

	uint256 immutable tokenNumber = 3;

	address[] tokens;

	/* 
    初始化：建立好一个测试环境，包括部署池子工厂合约，创建测试代币，创建测试账户等。
     */
	function run() public {
		/* 配置Uniswap环境 */
		vm.startBroadcast(deployer);

		address nbt = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
		address WETH9 = address(new WETH());
		poolFactory = new OutswapV1Factory(deployer);
		swapRouter = new OutswapV1Router(address(poolFactory), WETH9);

		console2.log("Factory address: ", address(poolFactory));
		console2.log("Router address: ", address(swapRouter));
		console2.log("WETH address: ", WETH9);
		

		// 部署3个token
		tokens.push(0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1);
		tokens.push(0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f);
		tokens.push(0x7a2088a1bFc9d81c55368AE168C2C02570cB814F);

		IERC20(nbt).approve(address(swapRouter), type(uint256).max);

		swapRouter.addLiquidityETH{value: 2000}(
        nbt,
        2000,
      	0,
        0,
        deployer,
        block.timestamp + 1 days);

		vm.stopBroadcast();
	}

	function getToken() internal {
		for (uint256 i = 0; i < tokenNumber; i++) {
			address token = address(new TestERC20(type(uint256).max / 2));
			tokens.push(token);
			safeApprove(
				token,
				address(swapRouter),
				type(uint256).max / 2
			);
		}
	}

	function addLiquidity(
        address tokenA,
        address tokenB
	)
		internal
		virtual
		returns (uint amountA, uint amountB, uint liquidity)
	{
		console2.log("addLiquidity");
		(tokenA, tokenB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

		swapRouter.addLiquidity(
        tokenA,
        tokenB,
        1001,
        1001,
        0,
        0,
        deployer,
        block.timestamp + 1 days);
	}

	function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

	function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }
}
