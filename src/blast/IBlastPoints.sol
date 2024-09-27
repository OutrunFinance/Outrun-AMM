// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

interface IBlastPoints {
    function configurePointsOperator(address operator) external;

    function configurePointsOperatorOnBehalf(address contractAddress, address operator) external;
}