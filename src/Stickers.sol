// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {IPrinter} from "./interfaces/IPrinter.sol";
import {StickerLib} from "./StickerLib.sol";
import {PrinterLib} from "./PrinterLib.sol";

/**
 * @dev the `owner` for mvp sake is the storefront but in reality will be a StickerMinter
 *     contract on the L2 which is in communication with the Storefront
 */
contract Stickers is ERC1155, Owned {
    error InvalidPrinterResponse();

    constructor() Owned(msg.sender) {}

    function mint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    )
        external
        onlyOwner
    {
        // [0] is safe because of 0 length check in Storefront
        // printer is guaranteed to be identical for all tokenIds
        (,,, address printer) = StickerLib.peel(ids[0]);

        if (PrinterLib.shouldCallOnBeforePrint(printer)) {
            if (
                IPrinter(printer).onBeforePrint(to, ids, amounts, data)
                    != IPrinter.onBeforePrint.selector
            ) {
                revert InvalidPrinterResponse();
            }
        }

        _batchMint(to, ids, amounts, data);
    }

    function burn(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    )
        external
        onlyOwner
    {
        _batchBurn(from, ids, amounts);

        // [0] is safe because of 0 length check in Storefront
        // printer is guaranteed to be identical for all tokenIds
        (,,, address printer) = StickerLib.peel(ids[0]);

        if (PrinterLib.shouldCallOnAfterStick(printer)) {
            if (
                IPrinter(printer).onAfterStick(from, ids, amounts, data)
                    != IPrinter.onAfterStick.selector
            ) {
                revert InvalidPrinterResponse();
            }
        }
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        // TODO: unpack id, call uri on printer
        (, uint8 id,, address printer) = StickerLib.peel(tokenId);
        // TODO: trycatch
        return IPrinter(printer).uri(id);
    }
}
