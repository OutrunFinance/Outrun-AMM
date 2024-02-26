//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

interface IOutswapV1Callee {
    function OutswapV1Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
