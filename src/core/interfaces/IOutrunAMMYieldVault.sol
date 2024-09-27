//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

interface IOutrunAMMYieldVault {
    function isValidPair(address pair) external view returns (bool);

    function initialize(address _facotry) external;

    function claimBETHYield(address pair, address maker) external;

    function claimUSDBYield(address pair, address maker) external;

    event ClaimBETHYield(address pair, address maker, uint256 accruedYield);

    event ClaimUSDBYield(address pair, address maker, uint256 accruedYield);

    error ZeroInput();

    error InValidPair();
}
