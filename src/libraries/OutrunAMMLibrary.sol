//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {IOutrunAMMPair} from "../core/interfaces/IOutrunAMMPair.sol";

library OutrunAMMLibrary {
    uint256 internal constant RATIO = 10000;
    
    error ZeroAddress();

    error IdenticalAddresses();

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
                            /* bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(OutrunAMMPair).creationCode)); */
                            hex"f52fc9f1359be155b90c9431d42b6d85340b12743086a3ba41d0297b047c675a" // init code hash
                        )
                    )
                )
            )
        );
    }
}
