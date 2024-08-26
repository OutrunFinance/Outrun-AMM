// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import "../src/core/OutrunAMMERC20.sol";
import "../src/core/OutrunAMMPair01.sol";
import "../src/core/OutrunAMMPair02.sol";
import "../src/core/OutrunAMMFactory01.sol";
import "../src/core/OutrunAMMFactory02.sol";
import "../src/router/OutrunAMMRouter01.sol";
import "../src/router/OutrunAMMRouter02.sol";
import "../src/referral/ReferralManager.sol";
import "../src/router/OutrunMulticall.sol";

contract OutrunAMMScript is BaseScript {
    address internal WETH;
    address internal owner;
    address internal feeTo;
    address internal registrar;
    address internal signer;
    address internal referralManager;

    OutrunAMMFactory01 internal factory01;
    OutrunAMMFactory02 internal factory02;

    function run() public broadcaster {
        WETH = vm.envAddress("WETH");
        owner = vm.envAddress("OWNER");
        feeTo = vm.envAddress("FEE_TO");
        registrar = vm.envAddress("REGISTRAR");
        signer = vm.envAddress("SIGNER");
        
        // console.log("0.3% Fee Pair initcode:");
        // console.logBytes32(keccak256(abi.encodePacked(type(OutrunAMMPair01).creationCode)));

        // console.log("1% Fee Pair initcode:");
        // console.logBytes32(keccak256(abi.encodePacked(type(OutrunAMMPair02).creationCode)));

        // // ReferralManager
        // referralManager = address(new ReferralManager(registrar, signer));
        // console.log("ReferralManager deployed on %s", referralManager);

        // // Multicall
        // address multicall = address(new OutrunMulticall());
        // console.log("OutrunMulticall deployed on %s", multicall);

        // // OutrunAMMFactory01
        // factory01 = new OutrunAMMFactory01(owner);
        // factory01.setFeeTo(feeTo);
        // address factory01Addr = address(factory01);
        // console.log("OutrunAMMFactory01 deployed on %s", factory01Addr);

        // // OutrunAMMFactory02
        // factory02 = new OutrunAMMFactory02(owner);
        // factory02.setFeeTo(feeTo);
        // address factory02Addr = address(factory02);
        // console.log("OutrunAMMFactory02 deployed on %s", factory02Addr);

        // OutrunAMMRouter01
        // OutrunAMMRouter01 router01 = new OutrunAMMRouter01(0x73249d1DF1434228693Cce32C2b97EE5BD464220, WETH, 0xC227bA17a4bF33945eBD9B9CCa6b2039d8095b41);
        // address router01Addr = address(router01);
        // console.log("OutrunAMMRouter01 deployed on %s", router01Addr);

        // OutrunAMMRouter02
        OutrunAMMRouter02 router02 = new OutrunAMMRouter02(0x5E53a7C3753B46BE021848c62274FEeAf28A349e, WETH, 0xC227bA17a4bF33945eBD9B9CCa6b2039d8095b41);
        address router02Addr = address(router02);
        console.log("OutrunAMMRouter02 deployed on %s", router02Addr);
    }
}
