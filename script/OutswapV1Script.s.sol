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
        
        console.log("0.3% Fee Pair initcode:");
        console.logBytes32(keccak256(abi.encodePacked(type(OutswapV1Pair01).creationCode, abi.encode(gasManager))));

        console.log("1% Fee Pair initcode:");
        console.logBytes32(keccak256(abi.encodePacked(type(OutswapV1Pair02).creationCode, abi.encode(gasManager))));

        // ReferralManager
        referralManager = address(new ReferralManager(registrar, gasManager));
        console.log("ReferralManager deployed on %s", referralManager);

        // Multicall
        address multicall = address(new OutrunMulticall(gasManager));
        console.log("OutrunMulticall deployed on %s", multicall);

        // OutswapV1Factory01
        factory01 = new OutswapV1Factory01(owner, gasManager);
        factory01.setFeeTo(feeTo);
        address factory01Addr = address(factory01);
        console.log("OutswapV1Factory01 deployed on %s", factory01Addr);

        // OutswapV1Factory02
        factory02 = new OutswapV1Factory02(owner, gasManager);
        factory02.setFeeTo(feeTo);
        address factory02Addr = address(factory02);
        console.log("OutswapV1Factory02 deployed on %s", factory02Addr);

        // OutswapV1Router01
        address router01Addr = address(new OutswapV1Router01(factory01Addr, orETH, orUSD, USDB, referralManager, gasManager));
        console.log("OutswapV1Router01 deployed on %s", router01Addr);

        // OutswapV1Router02
        address router02Addr = address(new OutswapV1Router02(factory02Addr, orETH, orUSD, USDB, referralManager, gasManager));
        console.log("OutswapV1Router02 deployed on %s", router02Addr);
    }
}
