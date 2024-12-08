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
    address internal blastGovernor;
    address internal pointsOperator;
    address internal feeTo;

    function run() public broadcaster {
        SY_BETH = vm.envAddress("SY_BETH");
        SY_USDB = vm.envAddress("SY_USDB");
        owner = vm.envAddress("OWNER");
        feeTo = vm.envAddress("FEE_TO");

        blastGovernor = vm.envAddress("BLAST_GOVERNOR");
        pointsOperator = vm.envAddress("POINTS_OPERATOR");
        WETH = vm.envAddress("TESTNET_WETH");
        USDB = vm.envAddress("TESTNET_USDB");
        
        console.log("Pair initcode:");
        console.logBytes32(keccak256(abi.encodePacked(type(OutrunAMMPair).creationCode, abi.encode(blastGovernor))));

        // 0.3% fee
        address factory01 = deployVaultAndFactory(30);

        // 1% fee
        address factory02 = deployVaultAndFactory(100);

        // OutrunAMMRouter
        deployOutrunAMMRouter(factory01, factory02);
    }

    function deployVaultAndFactory(uint256 swapFeeRate) internal returns (address factoryAddr) {
        OutrunAMMYieldVault yieldVault = new OutrunAMMYieldVault(SY_BETH, SY_USDB, blastGovernor);
        address yieldVaultAddr = address(yieldVault);
        OutrunAMMFactory factory = new OutrunAMMFactory(owner, blastGovernor, WETH, USDB, yieldVaultAddr, pointsOperator, swapFeeRate);
        factory.setFeeTo(feeTo);

        factoryAddr = address(factory);
        yieldVault.initialize(factoryAddr);

        console.log("%d fee OutrunAMMYieldVault deployed on %s", swapFeeRate, yieldVaultAddr);
        console.log("%d fee OutrunAMMFactory deployed on %s", swapFeeRate, factoryAddr);
    }

    function deployOutrunAMMRouter(address factory01, address factory02) internal {
        OutrunAMMRouter router = new OutrunAMMRouter(
            factory01, 
            factory02, 
            WETH,
            blastGovernor
        );
        address routerAddr = address(router);
        console.log("OutrunAMMRouter deployed on %s", routerAddr);
    }
}
