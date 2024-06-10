// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import "../src/core/OutswapV1ERC20.sol";
import "../src/core/OutswapV1Pair.sol";
import "../src/core/OutswapV1Factory.sol";
import "../src/router/OutswapV1Router.sol";

contract OutswapV1Script is BaseScript {
    address internal orETH;
    address internal orUSD;
    address internal USDB;
    address internal owner;
    address internal feeTo;
    address internal gasManager;

    OutswapV1Factory internal factory;

    function run() public broadcaster {
        orETH = vm.envAddress("ORETH");
        orUSD = vm.envAddress("ORUSD");
        USDB = vm.envAddress("USDB");
        owner = vm.envAddress("OWNER");
        feeTo = vm.envAddress("FEE_TO");
        gasManager = vm.envAddress("GAS_MANAGER");
        
        bytes32 initCodeHash = keccak256(abi.encodePacked(type(OutswapV1Pair).creationCode, abi.encode(gasManager)));
        console.logBytes32(initCodeHash);

        //deployFactory();
        deployRouter(0x583758BBD5B5fAF2983Be70B8E551829E1fbCc91);
    }

    function deployFactory() internal {
        factory = new OutswapV1Factory(owner, gasManager);
        factory.setFeeTo(feeTo);

        console.log("OutswapV1Factory deployed on %s", address(factory));
    }

    function deployRouter(address factoryAddr) internal {
        OutswapV1Router router = new OutswapV1Router(factoryAddr, orETH, orUSD, USDB, gasManager);
        console.log("OutswapV1Router deployed on %s", address(router));
    }
}