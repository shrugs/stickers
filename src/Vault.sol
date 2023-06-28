// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {frxETHMinter} from "./interfaces/frxETHMinter.sol";

/// @title Vault that backs stickers with frxETH
contract Vault {
    frxETHMinter public immutable $minter;

    constructor(frxETHMinter minter) {
        $minter = minter;
    }
}
