// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import "../src/core/OutswapV1ERC20.sol";
import "../src/core/OutswapV1Pair.sol";
import "../src/core/OutswapV1Factory.sol";
import "../src/router/OutswapV1Router.sol";

contract OutswapV1Script is BaseScript {
    function run() public broadcaster {
        address RETH = 0x4E06Dc746f8d3AB15BC7522E2B3A1ED087F14617;
        address RUSD = 0x671540e1569b8E82605C3eEA5939d326C4Eda457;
        address USDB = 0x4200000000000000000000000000000000000022;
        OutswapV1Factory factory = new OutswapV1Factory(owner, gasManager);
        factory.setFeeTo(feeTo);
        OutswapV1Router router = new OutswapV1Router(address(factory), RETH, RUSD, USDB, gasManager);

        console.log("OutswapV1Factory deployed on %s", address(factory));
        console.log("OutswapV1Router deployed on %s", address(router));
    }
}