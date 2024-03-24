//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOutswapV1Factory.sol";
import "./OutswapV1Pair.sol";
import "../blast/GasManagerable.sol";

contract OutswapV1Factory is IOutswapV1Factory, Ownable, GasManagerable {
    address public feeTo;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    constructor(address owner, address _gasManager) Ownable(owner) GasManagerable(_gasManager) {}

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "OutswapV1: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "OutswapV1: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "OutswapV1: PAIR_EXISTS"); // single check is sufficient
        bytes32 _salt = keccak256(abi.encodePacked(token0, token1));
        pair = address(new OutswapV1Pair{salt: _salt}(gasManager()));
        IOutswapV1Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }
}
