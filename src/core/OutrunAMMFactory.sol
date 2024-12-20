//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IOutrunAMMPair, OutrunAMMPair} from "./OutrunAMMPair.sol";
import {IOutrunAMMFactory} from "./interfaces/IOutrunAMMFactory.sol";

contract OutrunAMMFactory is IOutrunAMMFactory, Ownable {
    uint256 public immutable swapFeeRate;

    address public feeTo;
    address[] public allPairs;
    
    mapping(address => mapping(address => address)) public getPair;

    constructor(
        address owner_, 
        uint256 swapFeeRate_
    ) Ownable(owner_) {
        swapFeeRate = swapFeeRate_;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, IdenticalAddresses());

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), ZeroAddress());
        require(getPair[token0][token1] == address(0), PairExists()); // single check is sufficient

        bytes32 _salt = keccak256(abi.encodePacked(token0, token1, swapFeeRate));
        pair = address(new OutrunAMMPair{salt: _salt}());
        IOutrunAMMPair(pair).initialize(token0, token1, swapFeeRate);
        
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }
}