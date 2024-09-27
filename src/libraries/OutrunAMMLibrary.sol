//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "../core/interfaces/IOutrunAMMPair.sol";

library OutrunAMMLibrary {
    uint256 internal constant RATIO = 10000;

    error ZeroAddress();

    error InvalidPath();

    error IdenticalAddresses();

    error InsufficientAmount();
    
    error InsufficientLiquidity();

    error InsufficientInputAmount();

    error InsufficientOutputAmount();

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, IdenticalAddresses());
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), ZeroAddress());
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB, uint256 swapFeeRate) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1, swapFeeRate)),
                            /* bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(OutrunAMMPair01).creationCode, abi.encode(gasManager))); */
                            hex"484ae7d9b096a8b3e29dfdd817bcb852e6247163a8dcf1d7a772e88b7e68e13e" // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory, 
        address tokenA, 
        address tokenB,
        uint256 swapFeeRate
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IOutrunAMMPair(pairFor(factory, tokenA, tokenB, swapFeeRate)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, InsufficientAmount());
        require(reserveA > 0 && reserveB > 0, InsufficientLiquidity());
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, uint256 swapFeeRate) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, InsufficientInputAmount());
        require(reserveIn > 0 && reserveOut > 0, InsufficientLiquidity());
        uint256 amountInWithFee = amountIn * (RATIO - swapFeeRate);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * RATIO + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut, uint256 swapFeeRate) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, InsufficientOutputAmount());
        require(reserveIn > 0 && reserveOut > 0, InsufficientLiquidity());
        uint256 numerator = reserveIn * amountOut * RATIO;
        uint256 denominator = (reserveOut - amountOut) * (RATIO - swapFeeRate);
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path, uint256 swapFeeRate) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, InvalidPath());
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1], swapFeeRate);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, swapFeeRate);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path, uint256 swapFeeRate) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, InvalidPath());
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i], swapFeeRate);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, swapFeeRate);
        }
    }
}
