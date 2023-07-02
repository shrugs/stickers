// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {IStickerPrinter} from "./interfaces/IStickerPrinter.sol";
import {StickerLib} from "./StickerLib.sol";

/**
 * @dev the `owner` for mvp sake is the storefront but in reality will be a StickerMinter
 *     contract on the L2 which is in communication with the Storefront
 */
contract Stickers is ERC1155, Owned {
    constructor() Owned(msg.sender) {}

    function mint(address to, uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
        return _batchMint(to, ids, amounts, "");
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        // TODO: unpack id, call uri on printer
        (, uint8 id,, address printer) = StickerLib.peel(tokenId);
        // TODO: trycatch
        return IStickerPrinter(printer).uri(id);
    }
}
