// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import {IOutrunDeployer} from "./IOutrunDeployer.sol";
import {OutrunAMMPair} from "../src/core/OutrunAMMPair.sol";
import {OutrunAMMERC20} from "../src/core/OutrunAMMERC20.sol";
import {OutrunAMMRouter} from "../src/router/OutrunAMMRouter.sol";
import {ReferralManager} from "../src/referral/ReferralManager.sol";
import {OutrunAMMFactory, IOutrunAMMFactory} from "../src/core/OutrunAMMFactory.sol";

contract OutrunAMMScript is BaseScript {
    address internal owner;
    address internal feeTo;
    address internal referralManager;
    address internal OUTRUN_DEPLOYER;

    address internal WETH;

    function run() public broadcaster {
        owner = vm.envAddress("OWNER");
        feeTo = vm.envAddress("FEE_TO");
        OUTRUN_DEPLOYER = vm.envAddress("OUTRUN_DEPLOYER");
        
        console.log("Pair initcode:");
        console.logBytes32(keccak256(abi.encodePacked(type(OutrunAMMPair).creationCode)));

        _deployOnBNBChain();
        
        // ReferralManager
        // referralManager = address(new ReferralManager(owner));
        // console.log("ReferralManager deployed on %s", referralManager);
    }

    function _deployOnBNBChain() internal {
        WETH = vm.envAddress("BSC_TESTNET_WBNB");
        _deploy();
    }

    function _deploy() internal {
        // 0.3% fee
        address factory0 = _deployFactory(30, 2);

        // 1% fee
        address factory1 = _deployFactory(100, 2);

        // OutrunAMMRouter
        _deployOutrunAMMRouter(factory0, factory1, 2);
    }

    function _deployFactory(uint256 swapFeeRate, uint256 version) internal returns (address factoryAddr) {
        // Deploy OutrunAMMFactory By OutrunDeployer
        bytes32 salt = keccak256(abi.encodePacked("OutrunAMMFactory", swapFeeRate, version));
        bytes memory creationCode = abi.encodePacked(
            type(OutrunAMMFactory).creationCode,
            abi.encode(owner, swapFeeRate)
        );
        factoryAddr = IOutrunDeployer(OUTRUN_DEPLOYER).deploy(salt, creationCode);
        IOutrunAMMFactory(factoryAddr).setFeeTo(feeTo);

        console.log("%d fee OutrunAMMFactory deployed on %s", swapFeeRate, factoryAddr);
    }

    function _deployOutrunAMMRouter(address factory0, address factory01, uint256 version) internal {
        // Deploy OutrunAMMFactory By OutrunDeployer
        bytes32 salt = keccak256(abi.encodePacked("OutrunAMMRouter", version));
        bytes memory creationCode = abi.encodePacked(
            type(OutrunAMMRouter).creationCode,
            abi.encode(factory0, factory01, WETH)
        );
        address routerAddr = IOutrunDeployer(OUTRUN_DEPLOYER).deploy(salt, creationCode);

        console.log("OutrunAMMRouter deployed on %s", routerAddr);
    }
}
