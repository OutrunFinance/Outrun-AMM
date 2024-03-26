//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma abicoder v2;

import {BaseDeploy} from "./BaseDeploy.t.sol";
import {OutswapV1Library} from 'src/libraries/OutswapV1Library.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RouterUSDBMOCK is BaseDeploy {
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    fallback() external payable {}

    /* using USDB and token0 to add liquidity */
    function test_addLiquidityUSDB() public {
        uint256 liquidity = addLiquidityTokenAndUSDB(tokens[0]);
        assertEq(liquidity, 1 ether - MINIMUM_LIQUIDITY);
    }

    function test_addLiquidityETHAndUSDB() public {
        uint256 liquidity = addLiquidityTokenAndUSDB(RETH9);
        assertEq(liquidity, 1 ether - MINIMUM_LIQUIDITY);
    }

    function test_removeLiquidityUSDB() public {
        uint256 liquidity = addLiquidityTokenAndUSDB(tokens[0]);
        removeLiquidityTokenAndUSDB(tokens[0], liquidity);
    }

    function test_removeLiquidityETHAndUSDB() public {
        uint256 liquidity = addLiquidityTokenAndUSDB(RETH9);
        removeLiquidityTokenAndUSDB(RETH9, liquidity);
    }

    function addLiquidityTokenAndUSDB(address token) internal returns (uint256) {
        uint256 liquidity;
        (address _token0, address _token1) = OutswapV1Library.sortTokens(token, RUSD9);
        address pair = OutswapV1Library.pairFor(
            address(poolFactory),
            _token0,
            _token1
        );

        vm.startPrank(deployer);

        IERC20(USDB).approve(address(swapRouter), 1 ether);
        if(token != RETH9) {
            IERC20(tokens[0]).approve(address(swapRouter), 1 ether);
            (, , liquidity) = swapRouter.addLiquidityUSDB{value: 1 ether}(
                tokens[0],
                1 ether,
                1 ether,
                1 ether,
                1 ether,
                address(this),
                block.timestamp + 1
            );
        }
        else {
            (, , liquidity) = swapRouter.addLiquidityETHAndUSDB{value: 1 ether}(
                1 ether,
                1 ether,
                1 ether,
                address(this),
                block.timestamp + 1
            );
        }

        assertEq(poolFactory.getPair(_token0, _token1), pair);
        vm.stopPrank();

        return liquidity;
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
    function removeLiquidityUSDB(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountUSDBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountUSDB);

    function removeLiquidityETHAndUSDB(
        uint256 liquidity,
        uint256 amountETHMin,
        uint256 amountUSDBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH, uint256 amountUSDB);

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
