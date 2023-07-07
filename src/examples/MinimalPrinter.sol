// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {StickerLib} from "../StickerLib.sol";
import {BasePrinter} from "../BasePrinter.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IPrinter} from "../interfaces/IPrinter.sol";

/**
 * @notice a minimal printer
 * @dev allows printing of any id with any tier with any salt
 * takes 20% on primary sale
 * takes 5% on secondary sale
 */
contract MinimalPrinter is BasePrinter {
    address public immutable ARTIST;

    constructor(address artist) {
        ARTIST = artist;
    }

    function primarySaleInfo(
        uint256[] memory,
        uint256[] memory,
        uint256 deposit
    )
        external
        view
        returns (address receiver, uint256 saleAmount)
    {
        // 20% on top of deposit for primary printing sales
        return (ARTIST, FixedPointMathLib.mulWadUp(deposit, 20e16));
    }

    function royaltyInfo(
        uint256,
        uint256 salePrice
    )
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        // 5% royalties on secondary sales
        return (ARTIST, FixedPointMathLib.mulWadUp(salePrice, 5e16));
    }

    function uri(uint256 tokenId) external pure returns (string memory) {
        (, uint8 id, bytes8 salt,) = StickerLib.peel(tokenId);
        return string.concat(
            "https://example.com/", string(abi.encodePacked(salt)), "/", LibString.toString(id)
        );
    }
}
