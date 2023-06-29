// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Vault} from "./Vault.sol";

import {frxETHMinter} from "./interfaces/frxETHMinter.sol";
import {IStorefront} from "./interfaces/IStorefront.sol";
import {IStickerPrinter} from "./interfaces/IStickerPrinter.sol";

contract Storefront is IStorefront {
    mapping(uint256 => IStickerPrinter) public printer;

    Vault public immutable $vault;

    constructor(frxETHMinter minter) {
        $vault = new Vault(minter);
    }

    function mint(uint256[] ids) payable {}

    /// @notice registers a printer, given an optional salt
    function register(
        bytes32 salt,
        IStickerPrinter printer_
    ) external returns (uint256 tokenId) {
        tokenId = computeId(salt, printer_);
        printer[tokenId] = printer_;
    }

    /// @notice computes a token id using `salt` and `printer` implementation
    /// @dev use this to counterfactually list stickers for sale
    function computeId(
        bytes32 salt,
        IStickerPrinter printer_
    ) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(salt, printer_)));
    }
}
