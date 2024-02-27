// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

abstract contract BaseScript is Script {
    uint256 internal privateKey;
    address internal deployer;
    string internal mnemonic;
    
    function setUp() public virtual {
        privateKey = vm.envUint("PRIVATE_KEY");
        //mnemonic = vm.envString("MNEMONIC");
        deployer = vm.rememberKey(privateKey);
    }

    // function saveContract(string memory network, string memory name, address addr) public {
    //   string memory json1 = "key";
    //   string memory finalJson =  vm.serializeAddress(json1, "address", addr);
    //   string memory dirPath = string.concat(string.concat("output/", network), "/");
    //   vm.writeJson(finalJson, string.concat(dirPath, string.concat(name, ".json"))); 
    // }

    modifier broadcaster() {
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }
}