// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Vault} from "./Vault.sol";

import {Stickers} from "./Stickers.sol";
import {StickerLib} from "./StickerLib.sol";
import {frxETHMinter} from "./interfaces/frxETHMinter.sol";
import {IStickerPrinter} from "./interfaces/IStickerPrinter.sol";

contract Storefront {
    Vault public immutable $vault;
    Stickers public immutable $stickers;

    uint256 public constant BACKING = 0.0001 ether; // mvp: common only

    error InvalidIds();
    error InvalidAmountsLength();
    error MintFromSinglePrinter();
    error InvalidTier();

    constructor(frxETHMinter minter) {
        $vault = new Vault(minter);
        $stickers = new Stickers();
    }

    function mint(
        uint256[] memory ids,
        uint256[] memory amounts // TODO: permit
    ) external payable {
        // invariant: ids and amounts must be specified and equal length
        if (ids.length == 0) revert InvalidIds();
        if (ids.length != amounts.length) revert InvalidAmountsLength();

        address recipient = msg.sender;
        address printer;

        uint256 totalBacked = 0;
        uint256 len = ids.length;
        for (uint256 i = 0; i < len; ) {
            (uint8 tier, , , address _printer) = StickerLib.peel(ids[0]);

            // invariant: all ids must have the same printer
            if (printer == address(0)) {
                printer = _printer;
            } else if (_printer != printer) {
                revert MintFromSinglePrinter();
            }

            // invariant: the highest tier is 4
            if (tier > 4) revert InvalidTier();

            unchecked {
                totalBacked += amounts[i] * BACKING * (10 ** tier);
                i++;
            }
        }

        // TODO: before mint hook
        // IStickerPrinter(printer).canMint(recipient, ids, amounts);

        // TODO: calculate + pay artist share by consulting printer.royaltyInfo
        // (address receiver, ) = IStickerPrinter(printer).royaltyInfo(0, 0);
        // SafeTransferLib.transferETH()

        // vault input
        if (msg.value != 0) {
            // ETH
            require(msg.value == totalBacked, "msg.value != totalBacked");
            $vault.depositETH();
        } else {
            // frxETH
            // TODO: permit
            // amount is checked in transfer
            $vault.depositfrxETH(recipient, totalBacked);
        }

        // mint the ids to the recipient
        // mvp: mint directly rather than communicating over the bridge
        $stickers.mint(recipient, ids, amounts);
    }
}
