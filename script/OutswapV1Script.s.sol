// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import "../src/core/OutswapV1ERC20.sol";
import "../src/core/OutswapV1Pair01.sol";
import "../src/core/OutswapV1Pair02.sol";
import "../src/core/OutswapV1Factory01.sol";
import "../src/core/OutswapV1Factory02.sol";
import "../src/router/OutswapV1Router01.sol";
import "../src/router/OutswapV1Router02.sol";
import "../src/referral/ReferralManager.sol";
import "../src/router/OutrunMulticall.sol";

contract OutswapV1Script is BaseScript {
    address internal orETH;
    address internal orUSD;
    address internal USDB;
    address internal owner;
    address internal feeTo;
    address internal gasManager;
    address internal registrar;
    address internal signer;
    address internal referralManager;

    OutswapV1Factory01 internal factory01;
    OutswapV1Factory02 internal factory02;

    function run() public broadcaster {
        orETH = vm.envAddress("ORETH");
        orUSD = vm.envAddress("ORUSD");
        USDB = vm.envAddress("USDB");
        owner = vm.envAddress("OWNER");
        feeTo = vm.envAddress("FEE_TO");
        gasManager = vm.envAddress("GAS_MANAGER");
        registrar = vm.envAddress("REGISTRAR");
        signer = vm.envAddress("SIGNER");
        
        console.log("0.3% Fee Pair initcode:");
        console.logBytes32(keccak256(abi.encodePacked(type(OutswapV1Pair01).creationCode, abi.encode(gasManager))));

        console.log("1% Fee Pair initcode:");
        console.logBytes32(keccak256(abi.encodePacked(type(OutswapV1Pair02).creationCode, abi.encode(gasManager))));

        // // ReferralManager
        // referralManager = address(new ReferralManager(registrar, gasManager, signer));
        // console.log("ReferralManager deployed on %s", referralManager);

        // // Multicall
        // address multicall = address(new OutrunMulticall(gasManager));
        // console.log("OutrunMulticall deployed on %s", multicall);

        // // OutswapV1Factory01
        // factory01 = new OutswapV1Factory01(owner, gasManager);
        // factory01.setFeeTo(feeTo);
        // address factory01Addr = address(factory01);
        // console.log("OutswapV1Factory01 deployed on %s", factory01Addr);

        // // OutswapV1Factory02
        // factory02 = new OutswapV1Factory02(owner, gasManager);
        // factory02.setFeeTo(feeTo);
        // address factory02Addr = address(factory02);
        // console.log("OutswapV1Factory02 deployed on %s", factory02Addr);

        // OutswapV1Router01
        // OutswapV1Router01 router01 = new OutswapV1Router01(0x9d5e4DB7B0C2142e764A630d7EDFF29c5C3001DB, orETH, orUSD, USDB, 0x0ace66feF47f236b98d0fD5eC6e9A2D9453063F2, gasManager);
        // address router01Addr = address(router01);
        // console.log("OutswapV1Router01 deployed on %s", router01Addr);

        // // OutswapV1Router02
        // OutswapV1Router02 router02 = new OutswapV1Router02(0x87ac8C7877d8e89C7Dc89F1F86007F5EA8eD900A, orETH, orUSD, USDB, 0x0ace66feF47f236b98d0fD5eC6e9A2D9453063F2, gasManager);
        // address router02Addr = address(router02);
        // console.log("OutswapV1Router02 deployed on %s", router02Addr);
    }
}
