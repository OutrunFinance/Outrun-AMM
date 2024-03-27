//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma abicoder v2;

import {BaseDeploy} from "./BaseDeploy.t.sol";
import {OutswapV1Library} from 'src/libraries/OutswapV1Library.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IOutswapV1Pair} from "src/core/interfaces/IOutswapV1Pair.sol";

contract RouterUSDBMOCK is BaseDeploy {
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    fallback() external payable {}

    /* using USDB and token0 to add liquidity */
    function test_addLiquidityUSDB() public {
        (,,uint256 liquidity, )  = addLiquidityTokenAndUSDB(tokens[0],1 ether,1 ether);
        assertEq(liquidity, 1 ether - MINIMUM_LIQUIDITY);
    }

    function test_addLiquidityETHAndUSDB() public {
        (,,uint256 liquidity, )  = addLiquidityTokenAndUSDB(RETH9,1 ether,1 ether);
        assertEq(liquidity, 1 ether - MINIMUM_LIQUIDITY);
    }

    function test_AddLiquidityUSDBNoPair() public {
        (uint256 amount0, uint256 amount1, uint256 liquidity, address pair)  = addLiquidityTokenAndUSDB(tokens[0],1 ether,1 ether);

        assertEq(amount0, 1 ether);
        assertEq(amount1, 1 ether);
        assertEq(liquidity, 1 ether - MINIMUM_LIQUIDITY);

        assertEq(IOutswapV1Pair(pair).token0(), tokens[0]);
        assertEq(IOutswapV1Pair(pair).token1(), RUSD9);

        (uint256 reserve0, uint256 reserve1, ) = IOutswapV1Pair(pair)
            .getReserves();
        assertEq(reserve0, 1 ether);
        assertEq(reserve1, 1 ether);
        assertEq(IERC20(RUSD9).balanceOf(address(pair)), 1 ether);
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

    function testAddLiquidityExpired() public {
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
        (,,uint256 liquidity, ) = addLiquidityTokenAndUSDB(RETH9,1 ether,1 ether);
        removeLiquidityTokenAndUSDB(RETH9, liquidity);
    }

    /* swap token and usdb */
    function test_swapExactUSDBForTokens() public {
        (,,uint256 liquidity, )  = addLiquidityTokenAndUSDB(tokens[0],1 ether,1 ether);

        address[] memory path = new address[](2);
        path[0] = RUSD9;
        path[1] = tokens[0];

        vm.startPrank(deployer);
        IERC20(USDB).approve(address(swapRouter), 5000);
        uint256[] memory amounts = swapRouter.swapExactUSDBForTokens(5000, 4000, path, address(this), block.timestamp + 100);
        vm.stopPrank();

        uint256[] memory amountsCal = OutswapV1Library.getAmountsOut(OutswapV1Factory, 5000, path);
        assertEq(amounts[0], amountsCal[0]);
    }

    /* function */
    function addLiquidityTokenAndUSDB(address token, uint256 tokenAmount, uint256 usdbAmount) internal returns (uint256 amount0, uint256 amount1, uint256 liquidity, address pair) {
        (address _token0, address _token1) = OutswapV1Library.sortTokens(token, RUSD9);
        pair = OutswapV1Library.pairFor(
            address(poolFactory),
            _token0,
            _token1
        );

        vm.startPrank(deployer);

        IERC20(USDB).approve(address(swapRouter), usdbAmount);
        if(token != RETH9) {
            IERC20(tokens[0]).approve(address(swapRouter), tokenAmount);
            (amount0, amount1, liquidity) = swapRouter.addLiquidityUSDB(
                tokens[0],
                tokenAmount,
                usdbAmount,
                tokenAmount,
                usdbAmount,
                address(this),
                block.timestamp + 1
            );
        }
        else {
            (amount0, amount1, liquidity) = swapRouter.addLiquidityETHAndUSDB{value: tokenAmount}(
                usdbAmount,
                tokenAmount,
                usdbAmount,
                address(this),
                block.timestamp + 1
            );
        }

        assertEq(poolFactory.getPair(_token0, _token1), pair);
        vm.stopPrank();
    }

    function removeLiquidityTokenAndUSDB(address token, uint256 amount) internal {
        (address _token0, address _token1) = OutswapV1Library.sortTokens(token, RUSD9);
        address pair = OutswapV1Library.pairFor(address(poolFactory), _token0, _token1 );

        IERC20(pair).approve(address(swapRouter), amount);
        if(token != RETH9) {
            swapRouter.removeLiquidityUSDB(
                tokens[0],
                amount,
                0,
                0,
                address(this),
                block.timestamp + 1
            );
        }
        else {
            swapRouter.removeLiquidityETHAndUSDB(
                amount,
                0,
                0,
                address(this),
                block.timestamp + 1
            );
        }

    }

    /* 
    function swapExactUSDBForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactUSDB(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForUSDB(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapUSDBForExactTokens(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * SWAP with Pair(ETH, USDB) *
     */
    /*
    function swapExactETHForUSDB(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function swapUSDBForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactUSDBForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactUSDB(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts); */
}
