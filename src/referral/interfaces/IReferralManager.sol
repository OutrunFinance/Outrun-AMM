//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

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


    error ZeroAddress();

    error InvalidSigner();

    error AlreadyRegister();

    error ExpiredSignature(uint256 deadLine);


    event RegisterReferrer(address indexed account, address indexed referrer);

    event UpdateSigner(address oldSigner, address newSigner);
}
