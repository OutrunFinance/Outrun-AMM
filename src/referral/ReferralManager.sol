//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IReferralManager.sol";
import "../blast/GasManagerable.sol";

/**
 * @dev Referrer Manager, anyone can develop their own referrer manager and router contract to interface with Outrun AMM.
 */
contract ReferralManager is IReferralManager, Ownable, GasManagerable {
    mapping(address router => bool) private _authenticator;
    mapping(address account => address) private _referrers;

    constructor(address _owner, address _gasManager) Ownable(_owner) GasManagerable(_gasManager) {
    }

    function queryReferrer(address account) external view override returns (address) {
        return _referrers[account];
    }

    function registerReferrer(address account, address referrer) external override {
        require(_referrers[account] == address(0), "Already registered");
        require(_authenticator[msg.sender], "Invalid router");
        _referrers[account] = referrer;

        emit RegisterReferrer(account, referrer);
    }

    function authenticate(address router, bool state) external override onlyOwner {
        _authenticator[router] = state;

        emit Authenticate(router, state);
    }
}
