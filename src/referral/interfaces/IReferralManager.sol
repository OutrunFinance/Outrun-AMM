//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

interface IReferralManager {
    function queryReferrer(address account) external view returns (address referrer);

    function registerReferrer(address account, address referrer) external;

    function authenticate(address router, bool state) external;

    event RegisterReferrer(address indexed account, address indexed referrer);

    event Authenticate(address router, bool indexed state);
}
