// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import "../src/core/OutswapV1ERC20.sol";
import "../src/core/OutswapV1Pair.sol";
import "../src/core/OutswapV1Factory.sol";
import "../src/router/OutswapV1Router.sol";

contract OutswapV1Script is BaseScript {
    function run() public broadcaster {
        address RETH = 0x69D42F26c2709843433aE153979e089534Ed32b5;
        OutswapV1ERC20 erc20 = new OutswapV1ERC20();
        OutswapV1Factory factory = new OutswapV1Factory(0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8);
        OutswapV1Router router = new OutswapV1Router(address(factory), RETH);

        console.log("OutswapV1ERC20 deployed on %s", address(erc20));
        console.log("OutswapV1Factory deployed on %s", address(factory));
        console.log("OutswapV1Router deployed on %s", address(router));
    }
}