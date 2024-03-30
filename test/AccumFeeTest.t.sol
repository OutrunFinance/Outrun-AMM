//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma abicoder v2;

import {BaseDeploy} from "./BaseDeploy.t.sol";
import {console2} from "forge-std/Test.sol";

import {OutswapV1Library} from 'src/libraries/OutswapV1Library.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IOutswapV1Pair} from "src/core/interfaces/IOutswapV1Pair.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "src/libraries/FullMath.sol";


contract ACCUMFEEMOCK is BaseDeploy {

    address internal tokenPair;
    address internal ETHPair;

    uint256 totalSupply;
    uint256 accumFeePerLP;
    uint256 kLast;
    uint256 liquidity;

    uint256 Q128 = 0x100000000000000000000000000000000;

    address[] internal tokenToUsdPath;

    function setUp() public override {

        super.setUp();

        /* set pair */
        // token:USDB = 4:8
        (,, liquidity, tokenPair) = addLiquidityTokenAndUSDB(tokens[0], 4 ether, 8 ether);

        totalSupply = IERC20(tokenPair).totalSupply();
        accumFeePerLP = IAccumFeePerLP(tokenPair).accumFeePerLP();
        kLast = IOutswapV1Pair(tokenPair).kLast();

        assert(totalSupply > 5 ether);
        assertEq(accumFeePerLP, 0);

        tokenToUsdPath = new address[](2);
        tokenToUsdPath = [tokens[0], RUSD9];

    }

    function test_MintFee_NonProfit() public {
        uint112 reserve0;
        uint112 reserve1;
        uint256 totoalAmount = totalSupply + 1 ether;

        vm.startPrank(deployer);
        uint256[] memory amountsCal = OutswapV1Library.getAmountsIn(OutswapV1Factory, totoalAmount, tokenToUsdPath);
        IERC20(tokenToUsdPath[0]).transfer(tokenPair, amountsCal[0]);
        IOutswapV1Pair(tokenPair).swap(0, totoalAmount, address(this), "");
        vm.stopPrank();

        (reserve0, reserve1, ) = IOutswapV1Pair(tokenPair).getReserves();
        uint256 k = uint256(reserve0) * uint256(reserve1);

        accumFeePerLP = _accumulate(Math.sqrt(k), Math.sqrt(kLast));
        assertEq(accumFeePerLP, 0);
        uint256 accumFeePerLP_update = _accumulate_update(Math.sqrt(k), Math.sqrt(kLast));
        assert(accumFeePerLP_update > 0);
    }

    function test_MintFee_NonProfit_Times() public {
        uint256 amountOut = totalSupply / 10;
        uint256 totoalAmount = totalSupply;

        vm.startPrank(deployer);
        
        for (int i = 0; i < 10; i++){
            uint256[] memory amountsCal = OutswapV1Library.getAmountsIn(OutswapV1Factory, amountOut, tokenToUsdPath);
            IERC20(tokenToUsdPath[0]).transfer(tokenPair, amountsCal[0]);
            IOutswapV1Pair(tokenPair).swap(0, amountOut, address(this), "");

            accumFeePerLP = IAccumFeePerLP(tokenPair).accumFeePerLP();
            assertEq(accumFeePerLP, 0);
        }
        vm.stopPrank();
    }

    /**
     * forge-config: default.fuzz.runs = 10240
     * forge-config: default.fuzz.max-test-rejects = 10240
     */
    function testFuzz_MintFee(uint256 amountOut) public {
        vm.assume(amountOut > 0 && amountOut < 7.5 ether); // < 7.5 防止溢出

        vm.startPrank(deployer);
        uint256[] memory amountsCal = OutswapV1Library.getAmountsIn(OutswapV1Factory, amountOut, tokenToUsdPath);
        IERC20(tokenToUsdPath[0]).transfer(tokenPair, amountsCal[0]);
        IOutswapV1Pair(tokenPair).swap(0, amountOut, address(this), "");
        vm.stopPrank();

        accumFeePerLP = IAccumFeePerLP(tokenPair).accumFeePerLP();
        assertEq(accumFeePerLP, 0);
    }

    /* Revise */
    function test_MintFee_Fix() public {
        uint256 amountOut = totalSupply;

        vm.startPrank(deployer);
        uint256[] memory amountsCal = OutswapV1Library.getAmountsIn(OutswapV1Factory, amountOut, tokenToUsdPath);
        IERC20(tokenToUsdPath[0]).transfer(tokenPair, amountsCal[0]);
        IOutswapV1Pair(tokenPair).swap(0, amountOut, address(this), "");
        vm.stopPrank();

        accumFeePerLP = get_accumFeePerLP(accumFeePerLP);
        assert(accumFeePerLP > 0);
        console2.log("accumFeePerLP: ", accumFeePerLP);
        console2.log('amountsCal[0]:', amountsCal[0]);
    }

    function test_MintFee_Fix_In() public {
        uint256 amountIn= 100000;

        vm.startPrank(deployer);
        IERC20(tokenToUsdPath[0]).approve(address(swapRouter), amountIn);
        swapRouter.swapExactTokensForUSDB(amountIn, 0, tokenToUsdPath, address(this), block.timestamp);
        vm.stopPrank();

        accumFeePerLP = get_accumFeePerLP(accumFeePerLP);
        uint256 feeGrowth = FullMath.mulDiv(accumFeePerLP, liquidity, Q128);
        assert(accumFeePerLP > 0);
        console2.log("accumFeePerLP:", accumFeePerLP); // accumFeePerLP: 374
        console2.log("feeGrowth: ", feeGrowth);
    }

    function test_MintFee_Fix_In_Times() public {
        uint256 amountIn= 10000;

        vm.startPrank(deployer);
        for (int i = 0; i < 10; i++){
            kLast = IOutswapV1Pair(tokenPair).kLast();
            IERC20(tokenToUsdPath[0]).approve(address(swapRouter), amountIn);
            swapRouter.swapExactTokensForUSDB(amountIn, 0, tokenToUsdPath, address(this), block.timestamp);
            accumFeePerLP = get_accumFeePerLP(accumFeePerLP);
        }
        vm.stopPrank();

        uint256 feeGrowth = FullMath.mulDiv(accumFeePerLP, liquidity, Q128);

        assert(accumFeePerLP > 0);
        console2.log("accumFeePerLP: ", accumFeePerLP);
        console2.log("feeGrowth: ", feeGrowth);
    }

    function get_accumFeePerLP(uint256 accumFeePerLPNow) public returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = IOutswapV1Pair(tokenPair).getReserves();
        uint256 k = uint256(reserve0) * uint256(reserve1);
        return _accumulate_update(Math.sqrt(k), Math.sqrt(kLast));
    }

    function _accumulate_update(uint256 rootK, uint256 rootKLast) internal  returns (uint256) {
        // emit log_named_decimal_uint("(rootK - rootKLast):", (rootK - rootKLast), 18);
        // emit log_named_decimal_uint("OutswapV1Pair", totalSupply, 18);
        return accumFeePerLP + FullMath.mulDiv(rootK - rootKLast, Q128, totalSupply);
    }

    /* Helper */
    function addLiquidityTokenAndUSDB(address token, uint256 amountToken, uint256 amountUSDB) internal returns (uint256 amount0, uint256 amount1, uint256 liquidity, address pair) {
        return super.addLiquidityTokenAndUSDB(token, amountToken, amountUSDB, address(this));
    }

    function removeLiquidityTokenAndUSDB(address token, uint256 amount) internal {
        super.removeLiquidityTokenAndUSDB(token, amount, address(this));
    }

    function _accumulate(uint256 rootK, uint256 rootKLast) internal  returns (uint256) {
        emit log_named_decimal_uint("(rootK - rootKLast):", (rootK - rootKLast), 18);
        emit log_named_decimal_uint("OutswapV1Pair", totalSupply, 18);
        return accumFeePerLP + ((rootK - rootKLast) / totalSupply);
    }
}

interface IAccumFeePerLP{
    function accumFeePerLP() external view returns (uint256);
}