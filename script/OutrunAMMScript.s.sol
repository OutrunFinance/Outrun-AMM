// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import "../src/core/OutrunAMMERC20.sol";
import "../src/core/OutrunAMMPair.sol";
import "../src/core/OutrunAMMFactory.sol";
import "../src/core/OutrunAMMYieldVault.sol";
import "../src/router/OutrunAMMRouter.sol";
import "../src/referral/ReferralManager.sol";
import "../src/router/OutrunMulticall.sol";

contract OutrunAMMScript is BaseScript {
    address internal WETH;
    address internal USDB;
    address internal SY_BETH;
    address internal SY_USDB;

    address internal owner;
    address internal gasManager;
    address internal pointsOperator;
    address internal feeTo;
    address internal registrar;
    address internal signer;

    function run() public broadcaster {
        WETH = vm.envAddress("WETH");
        USDB = vm.envAddress("USDB");
        SY_BETH = vm.envAddress("SY_BETH");
        SY_USDB = vm.envAddress("SY_USDB");
        owner = vm.envAddress("OWNER");
        gasManager = vm.envAddress("GAS_MANAGER");
        pointsOperator = vm.envAddress("POINTS_OPERATOR");
        feeTo = vm.envAddress("FEE_TO");
        registrar = vm.envAddress("REGISTRAR");
        signer = vm.envAddress("SIGNER");
        
        console.log("Pair initcode:");
        console.logBytes32(keccak256(abi.encodePacked(type(OutrunAMMPair).creationCode, abi.encode(gasManager))));

        // ReferralManager
        address referralManager = address(new ReferralManager(registrar, gasManager, signer));
        console.log("ReferralManager deployed on %s", referralManager);

        // Multicall
        address multicall = address(new OutrunMulticall(gasManager));
        console.log("OutrunMulticall deployed on %s", multicall);

        // 0.3% fee
        OutrunAMMYieldVault yieldVault01 = new OutrunAMMYieldVault(SY_BETH, SY_USDB, gasManager);
        address yieldVault01Addr = address(yieldVault01);
        OutrunAMMFactory factory01 = new OutrunAMMFactory(owner, gasManager, WETH, USDB, yieldVault01Addr, pointsOperator, 30);
        address factory01Addr = address(factory01);
        yieldVault01.initialize(factory01Addr);
        factory01.setFeeTo(feeTo);

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

        // OutrunAMMRouter01
        OutrunAMMRouter router01 = new OutrunAMMRouter(
            factory01Addr, 
            WETH, 
            referralManager, 
            gasManager
        );
        address router01Addr = address(router01);
        console.log("0.3% fee OutrunAMMRouter deployed on %s", router01Addr);

        // OutrunAMMRouter02
        OutrunAMMRouter router02 = new OutrunAMMRouter(
            factory02Addr, 
            WETH, 
            referralManager, 
            gasManager
        );
        address router02Addr = address(router02);
        console.log("1% fee OutrunAMMRouter deployed on %s", router02Addr);
    }
}
