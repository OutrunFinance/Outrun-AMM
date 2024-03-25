// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

interface IUSDB {
    function sharePrice() external view returns (uint256);
    function count() external view returns (uint256);
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);

    function remoteToken() external view returns (address);
    function bridge() external view returns (address);

    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
}
