// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "./BaseScript.s.sol";
import {OutrunAMMERC20} from "../src/core/OutrunAMMERC20.sol";
import {OutrunAMMPair} from "../src/core/OutrunAMMPair.sol";
import {OutrunAMMFactory} from "../src/core/OutrunAMMFactory.sol";
import {OutrunAMMYieldVault} from "../src/core/OutrunAMMYieldVault.sol";
import {OutrunAMMRouter} from "../src/router/OutrunAMMRouter.sol";

contract OutrunAMMScript is BaseScript {
    address internal WETH;
    address internal USDB;
    address internal SY_BETH;
    address internal SY_USDB;

    address internal owner;
    address internal gasManager;
    address internal pointsOperator;
    address internal feeTo;

    function run() public broadcaster {
        WETH = vm.envAddress("BLAST_WETH");
        USDB = vm.envAddress("USDB");
        SY_BETH = vm.envAddress("SY_BETH");
        SY_USDB = vm.envAddress("SY_USDB");
        owner = vm.envAddress("OWNER");
        gasManager = vm.envAddress("GAS_MANAGER");
        pointsOperator = vm.envAddress("POINTS_OPERATOR");
        feeTo = vm.envAddress("FEE_TO");
        
        console.log("Pair initcode:");
        console.logBytes32(keccak256(abi.encodePacked(type(OutrunAMMPair).creationCode, abi.encode(gasManager))));

        // 0.3% fee
        OutrunAMMYieldVault yieldVault01 = new OutrunAMMYieldVault(SY_BETH, SY_USDB, gasManager);
        address yieldVault01Addr = address(yieldVault01);
        OutrunAMMFactory factory01 = new OutrunAMMFactory(owner, gasManager, WETH, USDB, yieldVault01Addr, pointsOperator, 30);
        factory01.setFeeTo(feeTo);

        address factory01Addr = address(factory01);
        yieldVault01.initialize(factory01Addr);

        console.log("0.3% fee OutrunAMMYieldVault deployed on %s", yieldVault01Addr);
        console.log("0.3% fee OutrunAMMFactory deployed on %s", factory01Addr);

        // 1% fee
        OutrunAMMYieldVault yieldVault02 = new OutrunAMMYieldVault(SY_BETH, SY_USDB, gasManager);
        address yieldVault02Addr = address(yieldVault02);
        OutrunAMMFactory factory02 = new OutrunAMMFactory(owner, gasManager, WETH, USDB, yieldVault02Addr, pointsOperator, 100);
        factory02.setFeeTo(feeTo);

        address factory02Addr = address(factory02);
        yieldVault02.initialize(factory02Addr);

        console.log("1% fee OutrunAMMYieldVault deployed on %s", yieldVault02Addr);
        console.log("1% fee OutrunAMMFactory deployed on %s", factory02Addr);

        // OutrunAMMRouter
        OutrunAMMRouter router = new OutrunAMMRouter(
            factory01Addr, 
            factory02Addr, 
            WETH
        );
        address routerAddr = address(router);
        console.log("OutrunAMMRouter deployed on %s", routerAddr);
    }
}
