//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

interface IReferralManager {
    function referrerOf(address account) external view returns (address referrer);

    function registerReferrer(
        address account, 
        address referrer, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external;

    event RegisterReferrer(address indexed account, address indexed referrer);
}
