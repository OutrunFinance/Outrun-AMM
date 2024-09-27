// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

abstract contract Initializable {
    bool public initialized;

    /**
     * @dev Already initialized.
     */
    error InvalidInitialization();

    modifier initializer() {
        require(!initialized, InvalidInitialization());

        initialized = true;
        _;
    }
}
