//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

interface IOutswapV1Factory {
    struct FFPairFeeInfo{
        address ffPairFeeto;
        uint ffPairFeeExpireTime;
    }

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event RegisterFFPair(address indexed tokenA, address indexed tokenB, address ffPairFeeto, uint ffPairFeeExpireTime);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function registerFFPair(address tokenA, address tokenB, address ffPairFeeto, uint ffPairFeeExpireTime) external;
    
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
