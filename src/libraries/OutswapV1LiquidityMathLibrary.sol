//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/math/Math.sol";
import '../core/interfaces/IOutswapV1Pair.sol';
import '../core/interfaces/IOutswapV1ERC20.sol';
import '../core/interfaces/IOutswapV1Factory.sol';
import './OutswapV1Library.sol';

// library containing some math for dealing with the liquidity shares of a pair, e.g. computing their exact value
// in terms of the underlying tokens
library OutswapV1LiquidityMathLibrary {
    // computes the direction and magnitude of the profit-maximizing trade
    function computeProfitMaximizingTrade(
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 reserveA,
        uint256 reserveB
    ) pure internal returns (bool aToB, uint256 amountIn) {
        aToB = Math.mulDiv(reserveA, truePriceTokenB, reserveB) < truePriceTokenA;

        uint256 invariant = reserveA * reserveB;

        uint256 leftSide = Math.sqrt(
            Math.mulDiv(
                invariant * 1000,
                aToB ? truePriceTokenA : truePriceTokenB,
                (aToB ? truePriceTokenB : truePriceTokenA) * 997
            )
        );
        uint256 rightSide = (aToB ? reserveA * 1000 : reserveB * 1000) / 997;

        if (leftSide < rightSide) return (false, 0);

        // compute the amount that must be sent to move the price to the profit-maximizing price
        amountIn = leftSide - rightSide;
    }

    // gets the reserves after an arbitrage moves the price to the profit-maximizing ratio given an externally observed true price
    function getReservesAfterArbitrage(
        address factory,
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB
    ) view internal returns (uint256 reserveA, uint256 reserveB) {
        // first get reserves before the swap
        (reserveA, reserveB) = OutswapV1Library.getReserves(factory, tokenA, tokenB);

        require(reserveA > 0 && reserveB > 0, 'OutswapV1ArbitrageLibrary: ZERO_PAIR_RESERVES');

        // then compute how much to swap to arb to the true price
        (bool aToB, uint256 amountIn) = computeProfitMaximizingTrade(truePriceTokenA, truePriceTokenB, reserveA, reserveB);

        if (amountIn == 0) {
            return (reserveA, reserveB);
        }

        // now affect the trade to the reserves
        if (aToB) {
            uint amountOut = OutswapV1Library.getAmountOut(amountIn, reserveA, reserveB);
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            uint amountOut = OutswapV1Library.getAmountOut(amountIn, reserveB, reserveA);
            reserveB += amountIn;
            reserveA -= amountOut;
        }
    }

    // computes liquidity value given all the parameters of the pair
    function computeLiquidityValue(
        uint256 reservesA,
        uint256 reservesB,
        uint256 totalSupply,
        uint256 liquidityAmount,
        uint256 ffPairFeeExpireTime,
        bool feeOn,
        uint kLast
    ) internal view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        if (feeOn && kLast > 0) {
            uint rootK = Math.sqrt(reservesA * reservesB);
            uint rootKLast = Math.sqrt(kLast);
            if (rootK > rootKLast) {
                uint numerator1 = totalSupply;
                uint numerator2 = rootK - rootKLast;
                uint denominator = block.timestamp < ffPairFeeExpireTime ? rootKLast :  rootK * 3 + rootKLast;
                uint feeLiquidity = Math.mulDiv(numerator1, numerator2, denominator);
                totalSupply += feeLiquidity;
            }
        }
        return (reservesA * liquidityAmount / totalSupply, reservesB * liquidityAmount / totalSupply);
    }

    // get all current parameters from the pair and compute value of a liquidity amount
    // **note this is subject to manipulation, e.g. sandwich attacks**. prefer passing a manipulation resistant price to
    // #getLiquidityValueAfterArbitrageToPrice
    function getLiquidityValue(
        address factory,
        address tokenA,
        address tokenB,
        uint256 liquidityAmount
    ) internal view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        (uint256 reservesA, uint256 reservesB) = OutswapV1Library.getReserves(factory, tokenA, tokenB);
        IOutswapV1Pair pair = IOutswapV1Pair(OutswapV1Library.pairFor(factory, tokenA, tokenB));
        bool feeOn = IOutswapV1Factory(factory).feeTo() != address(0);
        uint kLast = feeOn ? pair.kLast() : 0;
        uint totalSupply = IOutswapV1ERC20(address(pair)).totalSupply();
        return computeLiquidityValue(reservesA, reservesB, totalSupply, liquidityAmount, pair.ffPairFeeExpireTime(), feeOn, kLast);
    }

    // given two tokens, tokenA and tokenB, and their "true price", i.e. the observed ratio of value of token A to token B,
    // and a liquidity amount, returns the value of the liquidity in terms of tokenA and tokenB
    function getLiquidityValueAfterArbitrageToPrice(
        address factory,
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 liquidityAmount
    ) internal view returns (
        uint256 tokenAAmount,
        uint256 tokenBAmount
    ) {
        bool feeOn = IOutswapV1Factory(factory).feeTo() != address(0);
        IOutswapV1Pair pair = IOutswapV1Pair(OutswapV1Library.pairFor(factory, tokenA, tokenB));
        uint kLast = feeOn ? pair.kLast() : 0;
        uint totalSupply = IOutswapV1ERC20(address(pair)).totalSupply();

        // this also checks that totalSupply > 0
        require(totalSupply >= liquidityAmount && liquidityAmount > 0, 'ComputeLiquidityValue: LIQUIDITY_AMOUNT');

        (uint reservesA, uint reservesB) = getReservesAfterArbitrage(factory, tokenA, tokenB, truePriceTokenA, truePriceTokenB);

        return computeLiquidityValue(reservesA, reservesB, totalSupply, liquidityAmount, pair.ffPairFeeExpireTime(), feeOn, kLast);
    }
}
