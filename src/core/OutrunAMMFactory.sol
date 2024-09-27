//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./OutrunAMMPair.sol";
import "./interfaces/IOutrunAMMFactory.sol";
import "../blast/GasManagerable.sol";

contract OutrunAMMFactory is IOutrunAMMFactory, Ownable, GasManagerable {
    address public immutable WETH;
    address public immutable USDB;
    address public immutable YIELD_VAULT;
    address public immutable pointsOperator;
    uint256 public immutable swapFeeRate;

    address public feeTo;
    address[] public allPairs;
    
    mapping(address => mapping(address => address)) public getPair;

    constructor(
        address owner_, 
        address gasManager_,
        address WETH_,
        address USDB_,
        address YIELD_VAULT_,
        address pointsOperator_,
        uint256 swapFeeRate_
    ) Ownable(owner_) GasManagerable(gasManager_) {
        WETH = WETH_;
        USDB = USDB_;
        YIELD_VAULT = YIELD_VAULT_;
        pointsOperator = pointsOperator_;
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
        pair = address(new OutrunAMMPair{salt: _salt}(gasManager, YIELD_VAULT));
        IOutrunAMMPair(pair).initialize(
            token0, 
            token1, 
            swapFeeRate, 
            tokenA == WETH || tokenB == WETH, 
            tokenA == USDB || tokenB == USDB
        );
        
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }
}
