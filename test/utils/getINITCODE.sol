//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma abicoder v2;

import {OutswapV1Pair} from "src/core/OutswapV1Pair.sol";
import {console2} from "forge-std/Test.sol";

// core合约任何一个函数修改之后，都需要重新编译，获取pair合约的字节码
function getINIT_CODE() {
    console2.logBytes32(keccak256(abi.encodePacked(type(OutswapV1Pair).creationCode)));
}
