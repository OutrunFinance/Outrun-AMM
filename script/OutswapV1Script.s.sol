// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import "../src/core/OutswapV1ERC20.sol";
import "../src/core/OutswapV1Pair.sol";
import "../src/core/OutswapV1Factory.sol";
import "../src/router/OutswapV1Router.sol";

contract OutswapV1Script is BaseScript {
    function run() public broadcaster {
        address RETH = 0x8921b78E6b521dF5F55eF41e1787100BD43c1366;
        address RUSD = 0xB0A16CF65F85e8A52C4462ADE453d0E6D4A5e9bC;
        address USDB = 0x4200000000000000000000000000000000000022;
        OutswapV1Factory factory = new OutswapV1Factory(0xcae21365145C467F8957607aE364fb29Ee073209);
        OutswapV1Router router = new OutswapV1Router(address(factory), RETH, RUSD, USDB);

        console.log("OutswapV1Factory deployed on %s", address(factory));
        console.log("OutswapV1Router deployed on %s", address(router));
    }
}