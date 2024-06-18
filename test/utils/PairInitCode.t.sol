//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma abicoder v2;

import {OutswapV1Pair0} from "src/core/OutswapV1Pair0.sol";
import {Test, console2} from "forge-std/Test.sol";

contract PairInitCode is Test {
    function testGetInitCode() view external {
        address gasManager = vm.envAddress("GAS_MANAGER");
        console2.logBytes32(keccak256(abi.encodePacked(type(OutswapV1Pair0).creationCode, abi.encode(gasManager))));
    }
}