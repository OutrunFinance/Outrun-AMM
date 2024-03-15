// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import "../src/core/OutswapV1ERC20.sol";
import "../src/core/OutswapV1Pair.sol";
import "../src/core/OutswapV1Factory.sol";
import "../src/router/OutswapV1Router.sol";

contract OutswapV1Script is BaseScript {
    function run() public broadcaster {
        address RETH = 0xdaC9Ed63dada8A7005ce2c69F8FF8bF6C272a3D0;
        address RUSD = 0xef2CdD12E6AE75C6e7ab69105520A12181991657;
        address USDB = 0x4200000000000000000000000000000000000022;
        OutswapV1Factory factory = new OutswapV1Factory(0xcae21365145C467F8957607aE364fb29Ee073209);
        OutswapV1Router router = new OutswapV1Router(address(factory), RETH, RUSD, USDB);

        console.log("OutswapV1Factory deployed on %s", address(factory));
        console.log("OutswapV1Router deployed on %s", address(router));
    }
}