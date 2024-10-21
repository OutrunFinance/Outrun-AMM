// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import "../src/core/OutrunAMMERC20.sol";
import "../src/core/OutrunAMMPair.sol";
import "../src/core/OutrunAMMFactory.sol";
import "../src/router/OutrunAMMRouter.sol";
import "../src/referral/ReferralManager.sol";
import "../src/router/OutrunMulticall.sol";

contract OutrunAMMScript is BaseScript {
    address internal WETH;
    address internal owner;
    address internal feeTo;
    address internal registrar;
    address internal signer;
    address internal referralManager;

    function run() public broadcaster {
        WETH = vm.envAddress("WETH");
        owner = vm.envAddress("OWNER");
        feeTo = vm.envAddress("FEE_TO");
        registrar = vm.envAddress("REGISTRAR");
        signer = vm.envAddress("SIGNER");
        
        console.log("Pair initcode:");
        console.logBytes32(keccak256(abi.encodePacked(type(OutrunAMMPair).creationCode)));

        // ReferralManager
        referralManager = address(new ReferralManager(registrar, signer));
        console.log("ReferralManager deployed on %s", referralManager);

        // Multicall
        address multicall = address(new OutrunMulticall());
        console.log("OutrunMulticall deployed on %s", multicall);

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
            WETH, 
            referralManager
        );
        address router01Addr = address(router01);
        console.log("0.3% fee OutrunAMMRouter deployed on %s", router01Addr);

        // 1% fee OutrunAMMRouter02
        OutrunAMMRouter router02 = new OutrunAMMRouter(
            factory02Addr, 
            WETH, 
            referralManager
        );
        address router02Addr = address(router02);
        console.log("1% fee OutrunAMMRouter deployed on %s", router02Addr);
    }
}
