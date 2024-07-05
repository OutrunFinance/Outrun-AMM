//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseDeploy} from "./BaseDeploy.t.sol";
import {OutswapV1Library01} from 'src/libraries/OutswapV1Library01.sol';
import {IOutswapV1Pair} from "src/core/interfaces/IOutswapV1Pair.sol";

contract RouterUSDBMOCK is BaseDeploy {
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    receive() external payable {}

    /* add liquidity */
    function test_addLiquidityUSDB() public {
        (,,uint256 liquidity, )  = addLiquidityTokenAndUSDB(tokens[0],1 ether,1 ether);
        assertEq(liquidity, 1 ether - MINIMUM_LIQUIDITY);
    }

    function test_addLiquidityETHAndUSDB() public {
        (,,uint256 liquidity, )  = addLiquidityTokenAndUSDB(ORETH,1 ether,1 ether);
        assertEq(liquidity, 1 ether - MINIMUM_LIQUIDITY);
    }

    function test_AddLiquidityUSDBNoPair() public {
        (uint256 amount0, uint256 amount1, uint256 liquidity, address pair)  = addLiquidityTokenAndUSDB(tokens[0],1 ether,1 ether);

        assertEq(amount0, 1 ether);
        assertEq(amount1, 1 ether);
        assertEq(liquidity, 1 ether - MINIMUM_LIQUIDITY);

        assertEq(IOutswapV1Pair(pair).token0(), tokens[0]);
        assertEq(IOutswapV1Pair(pair).token1(), ORUSD);

        (uint256 reserve0, uint256 reserve1, ) = IOutswapV1Pair(pair)
            .getReserves();
        assertEq(reserve0, 1 ether);
        assertEq(reserve1, 1 ether);
        assertEq(IERC20(ORUSD).balanceOf(address(pair)), 1 ether);
        assertEq(IERC20(tokens[0]).balanceOf(address(pair)), 1 ether);
    }

    function test_AddLiquidityInsufficientUsdbAmount() public {
        (,,uint256 liquidity, )  = addLiquidityTokenAndUSDB(tokens[0], 4 ether, 8 ether);

        vm.startPrank(deployer);
        IERC20(tokens[0]).approve(address(swapRouter), 1 ether);
        IERC20(USDB).approve(address(swapRouter), 2 ether);

        vm.expectRevert(bytes("OutswapV1Router: INSUFFICIENT_B_AMOUNT"));
        swapRouter.addLiquidityUSDB(
            tokens[0],
            1 ether,
            2 ether,
            1 ether,
            2.3 ether,
            address(this),
            block.timestamp + 1
        );
        vm.stopPrank();
    }

    function test_AddLiquidityExpired() public {
        vm.startPrank(deployer);
        rusd.approve(address(swapRouter), 1 ether);
        IERC20(tokens[0]).approve(address(swapRouter), 1 ether);

        vm.warp(2);
        vm.expectRevert(bytes("OutswapV1Router: EXPIRED"));
        swapRouter.addLiquidityUSDB(
            tokens[0],
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this),
            1
        );
        vm.stopPrank();
    }

    /* remove liquidity */
    function test_removeLiquidityUSDB() public {
        (,,uint256 liquidity, ) = addLiquidityTokenAndUSDB(tokens[0],1 ether,1 ether);
        removeLiquidityTokenAndUSDB(tokens[0], liquidity);
    }

    function test_removeLiquidityETHAndUSDB() public {
        (,,uint256 liquidity, ) = addLiquidityTokenAndUSDB(ORETH,1 ether,1 ether);
        removeLiquidityTokenAndUSDB(ORETH, liquidity);
    }

    /* swap token and usdb */
    function test_swapExactUSDBForTokens() public {
        (,,uint256 liquidity, )  = addLiquidityTokenAndUSDB(tokens[0],1 ether,1 ether);

        address[] memory path = new address[](2);
        path[0] = ORUSD;
        path[1] = tokens[0];

        vm.startPrank(deployer);
        IERC20(USDB).approve(address(swapRouter), 5000);
        uint256[] memory amounts = swapRouter.swapExactUSDBForTokens(5000, 4000, path, address(this), block.timestamp + 100);
        vm.stopPrank();

        uint256[] memory amountsCal = OutswapV1Library01.getAmountsOut(OutswapV1Factory, 5000, path);
        assertEq(amounts[0], amountsCal[0]);
    }

    function test_swapExactTokensForUSDB() public {
        (,,uint256 liquidity, )  = addLiquidityTokenAndUSDB(tokens[0],1 ether,1 ether);
        addLiquidityTokenAndUSDB(tokens[0],1 ether,1 ether);

        address[] memory path = new address[](2);
        path[1] = ORUSD;
        path[0] = tokens[0];

        vm.startPrank(deployer);
        IERC20(tokens[0]).approve(address(swapRouter), 5000);
        
        uint256[] memory amounts = swapRouter.swapTokensForExactUSDB(4000, 4500, path, address(this), block.timestamp + 100);
        vm.stopPrank();

        uint256[] memory amountsCal = OutswapV1Library01.getAmountsIn(OutswapV1Factory, 4000, path);
        assertEq(amounts[0], amountsCal[0]);
    }

    function test_swapExactETHForUSDB() public {
        (,,uint256 liquidity, )  = addLiquidityTokenAndUSDB(ORETH,1 ether,1 ether);
        addLiquidityTokenAndUSDB(tokens[0],1 ether,1 ether);

        address[] memory path = new address[](2);
        path[1] = ORUSD;
        path[0] = ORETH;

        vm.startPrank(deployer);
        IERC20(ORETH).approve(address(swapRouter), 5000);
        
        uint256[] memory amounts = swapRouter.swapExactETHForUSDB{value: 4500}(4000, path, address(this), block.timestamp + 100);
        vm.stopPrank();

        uint256[] memory amountsCal = OutswapV1Library01.getAmountsOut(OutswapV1Factory, 4500, path);
        assertEq(amounts[0], amountsCal[0]);
    }

    /* helper */
    function addLiquidityTokenAndUSDB(address token, uint256 amountToken, uint256 amountUSDB) internal returns (uint256 amount0, uint256 amount1, uint256 liquidity, address pair) {
        return super.addLiquidityTokenAndUSDB(token, amountToken, amountUSDB, address(this));
    }

    function removeLiquidityTokenAndUSDB(address token, uint256 amount) internal {
        super.removeLiquidityTokenAndUSDB(token, amount, address(this));
    }
}