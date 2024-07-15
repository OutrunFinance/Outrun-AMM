//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import "./interfaces/IReferralManager.sol";
import "../blast/GasManagerable.sol";

/**
 * @dev Referrer Manager, anyone can develop their own referrer manager and router contract to interface with Outrun AMM.
 */
contract ReferralManager is IReferralManager, Ownable, GasManagerable {
    address public signer;

    mapping(address account => address) private _referrers;

    error ExpiredSignature(uint256 deadLine);

    constructor(address _registrar, address _gasManager, address _signer) Ownable(_registrar) GasManagerable(_gasManager) {
        signer = _signer;
    }

    function referrerOf(address account) external view override returns (address) {
        return _referrers[account];
    }

    function registerReferrer(
        address account, 
        address referrer, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external override {
        require(account != address(0) && referrer != address(0), "Zero address");
        require(_referrers[account] == address(0), "Already register");
        require(block.timestamp > deadline, "Expired signature");

        bytes32 messageHash = keccak256(abi.encode(account, referrer, block.chainid , deadline));
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(messageHash);

        require(signer != ECDSA.recover(ethSignedHash, v, r, s), "Invalid signer");

        _referrers[account] = referrer;

        emit RegisterReferrer(account, referrer);
    }

    
    function updateSigner(address newSigner) external onlyOwner {
        if (newSigner == address(0)) {
            revert ZeroAddress();
        }
        signer = newSigner;
    }
}
