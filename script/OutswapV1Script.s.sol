// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import "../src/core/OutswapV1ERC20.sol";
import "../src/core/OutswapV1Pair0.sol";
import "../src/core/OutswapV1Pair1.sol";
import "../src/core/OutswapV1Factory0.sol";
import "../src/core/OutswapV1Factory1.sol";
import "../src/router/OutswapV1Router.sol";
import "../src/router/OutrunMulticall.sol";

contract OutswapV1Script is BaseScript {
    address internal orETH;
    address internal orUSD;
    address internal USDB;
    address internal owner;
    address internal feeTo;
    address internal gasManager;

    OutswapV1Factory0 internal factory0;
    OutswapV1Factory1 internal factory1;

    function run() public broadcaster {
        orETH = vm.envAddress("ORETH");
        orUSD = vm.envAddress("ORUSD");
        USDB = vm.envAddress("USDB");
        owner = vm.envAddress("OWNER");
        feeTo = vm.envAddress("FEE_TO");
        gasManager = vm.envAddress("GAS_MANAGER");
        
        console.log("0.3% Fee Pair initcode:");
        console.logBytes32(keccak256(abi.encodePacked(type(OutswapV1Pair0).creationCode, abi.encode(gasManager))));

        console.log("1% Fee Pair initcode:");
        console.logBytes32(keccak256(abi.encodePacked(type(OutswapV1Pair1).creationCode, abi.encode(gasManager))));

        // factory0 = new OutswapV1Factory0(owner, gasManager);
        // factory0.setFeeTo(feeTo);
        // address factory0Addr = address(factory0);
        // address router0Addr = deployRouter(factory0Addr);
        // console.log("OutswapV1Factory0 deployed on %s", factory0Addr);
        // console.log("OutswapV1Router0 deployed on %s", router0Addr);

        // The initCode for the OutswapV1Library needs to be modified first.
        // factory1 = new OutswapV1Factory1(owner, gasManager);
        // factory1.setFeeTo(feeTo);
        // address factory1Addr = address(factory1);
        // address router1Addr = deployRouter(factory1Addr);
        // console.log("OutswapV1Factory1 deployed on %s", factory1Addr);
        // console.log("OutswapV1Router1 deployed on %s", router1Addr);

        address multicall = address(new OutrunMulticall(gasManager));
        console.log("OutrunMulticall deployed on %s", multicall);

    }

    function deployRouter(address factoryAddr) internal returns (address routerAddr) {
        routerAddr = address(new OutswapV1Router(factoryAddr, orETH, orUSD, USDB, gasManager));
    }
}
