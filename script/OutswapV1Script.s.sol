// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import "../src/core/OutswapV1ERC20.sol";
import "../src/core/OutswapV1Pair.sol";
import "../src/core/OutswapV1Factory.sol";
import "../src/router/OutswapV1Router.sol";

contract OutswapV1Script is BaseScript {
    function run() public broadcaster {
        address orETH = vm.envAddress("ORETH");
        address orUSD = vm.envAddress("ORUSD");
        address USDB = vm.envAddress("USDB");
        address owner = vm.envAddress("OWNER");
        address feeTo = vm.envAddress("FEE_TO");
        address gasManager = vm.envAddress("GAS_MANAGER");
        
        OutswapV1Factory factory = new OutswapV1Factory(owner, gasManager);
        factory.setFeeTo(feeTo);
        OutswapV1Router router = new OutswapV1Router(address(factory), orETH, orUSD, USDB, gasManager);

        console.log("OutswapV1Factory deployed on %s", address(factory));
        console.log("OutswapV1Router deployed on %s", address(router));
    }
}