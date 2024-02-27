//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import './interfaces/IOutswapV1Factory.sol';
import './OutswapV1Pair.sol';
import "forge-std/console2.sol";

contract OutswapV1Factory is IOutswapV1Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    mapping(address => mapping(address => FFPairFeeInfo)) public ffPairRegistry;
    address[] public allPairs;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'OutswapV1: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'OutswapV1: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'OutswapV1: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(OutswapV1Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IOutswapV1Pair(pair).initialize(token0, token1);
        FFPairFeeInfo memory info = ffPairRegistry[token0][token1];
        address ffPairFeeto = info.ffPairFeeto;
        if (ffPairFeeto != address(0)) {
            IOutswapV1Pair(pair).setFFPairFeeInfo(ffPairFeeto, info.ffPairFeeExpireTime);
        }

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function registerFFPair(address tokenA, address tokenB, address ffPairFeeto, uint ffPairFeeExpireTime) external {
        require(msg.sender == feeToSetter, 'OutswapV1: FORBIDDEN');
        require(tokenA != tokenB, 'OutswapV1: IDENTICAL_ADDRESSES');
        FFPairFeeInfo memory info = FFPairFeeInfo(ffPairFeeto, ffPairFeeExpireTime);
        ffPairRegistry[tokenA][tokenB] = info;
        ffPairRegistry[tokenB][tokenA] = info;

        emit RegisterFFPair(tokenA, tokenB, ffPairFeeto, ffPairFeeExpireTime);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'OutswapV1: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'OutswapV1: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
