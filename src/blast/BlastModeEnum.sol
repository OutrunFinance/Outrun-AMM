// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

interface BlastModeEnum {
    enum YieldMode {
        AUTOMATIC,
        VOID,
        CLAIMABLE
    }

    enum GasMode {
        VOID,
        CLAIMABLE
    }
}