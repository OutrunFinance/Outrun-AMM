// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import {OutrunAMMERC20} from "../src/core/OutrunAMMERC20.sol";
import {OutrunAMMPair} from "../src/core/OutrunAMMPair.sol";
import {OutrunAMMFactory} from "../src/core/OutrunAMMFactory.sol";
import {OutrunAMMRouter} from "../src/router/OutrunAMMRouter.sol";
import {ReferralManager} from "../src/referral/ReferralManager.sol";

contract OutrunAMMScript is BaseScript {
    address internal WETH;
    address internal owner;
    address internal feeTo;
    address internal referralManager;

    function run() public broadcaster {
        WETH = vm.envAddress("WETH");
        owner = vm.envAddress("OWNER");
        feeTo = vm.envAddress("FEE_TO");
        
        console.log("Pair initcode:");
        console.logBytes32(keccak256(abi.encodePacked(type(OutrunAMMPair).creationCode)));

        // ReferralManager
        referralManager = address(new ReferralManager(owner));
        console.log("ReferralManager deployed on %s", referralManager);

        // 0.3% fee
        OutrunAMMFactory factory01 = new OutrunAMMFactory(owner, 30);
        factory01.setFeeTo(feeTo);

        address factory01Addr = address(factory01);
        console.log("0.3% fee OutrunAMMFactory deployed on %s", factory01Addr);

        // 1% fee
        OutrunAMMFactory factory02 = new OutrunAMMFactory(owner, 100);
        factory02.setFeeTo(feeTo);

        address factory02Addr = address(factory02);
        console.log("1% fee OutrunAMMFactory deployed on %s", factory02Addr);

        // 0.3% fee OutrunAMMRouter01
        OutrunAMMRouter router01 = new OutrunAMMRouter(
            factory01Addr, 
            WETH
        );
        address router01Addr = address(router01);
        console.log("0.3% fee OutrunAMMRouter deployed on %s", router01Addr);

        // 1% fee OutrunAMMRouter02
        OutrunAMMRouter router02 = new OutrunAMMRouter(
            factory02Addr, 
            WETH
        );
        address router02Addr = address(router02);
        console.log("1% fee OutrunAMMRouter deployed on %s", router02Addr);
    }
}
