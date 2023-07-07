// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IPrinter, IERC165} from "./interfaces/IPrinter.sol";
import {ERC165} from "openzeppelin/utils/introspection/ERC165.sol";

/**
 * @notice helpful base contract for Printers
 * @dev BasePrinter implements:
 *  - supportsInterface for IPrinter
 *  - stubs for hooks
 *
 * Inheritors implement:
 * - uri
 * - primarySaleInfo
 * - royaltyInfo
 * - hooks (enable by supportsInterface(IPrinter.[hook].selector))
 */
abstract contract BasePrinter is IPrinter, ERC165 {
    error NotImplemented();

    function onBeforePrint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    )
        external
        view
        virtual
        returns (bytes4)
    {
        ids;
        amounts;
        to;
        data;

        revert NotImplemented();
    }

    // function primarySaleInfo(
    //     uint256[] memory ids,
    //     uint256[] memory amounts,
    //     uint256 deposit
    // )
    //     external
    //     view
    //     virtual
    //     returns (address receiver, uint256 saleAmount)
    // {
    //     ids;
    //     amounts;
    //     deposit;
    //     receiver;
    //     saleAmount;

    //     // % of deposit like deposit.mulWadDown(20e16) // 20%
    //     // flat rate per sticker like tokenIds.length * FEE_PER_PRINT
    //     // per-tier rate with (uint8 tier,,,) StickerLib.peel(tokenIds[i])
    //     // ...etc
    //     revert NotImplemented();
    // }

    // /**
    //  * @dev Returns how much royalty is owed and to whom, based on a sale price that may be
    //  * denominated in any unit of exchange. The royalty amount is denominated and should be paid in
    //  * that same unit of exchange.
    //  */
    // function royaltyInfo(
    //     uint256 tokenId,
    //     uint256 salePrice
    // )
    //     external
    //     view
    //     virtual
    //     returns (address receiver, uint256 royaltyAmount)
    // {
    //     tokenId;
    //     salePrice;
    //     receiver;
    //     royaltyAmount;

    //     revert NotImplemented();
    // }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        // forgefmt: disable-next-item
        return
            interfaceId == type(IPrinter).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
