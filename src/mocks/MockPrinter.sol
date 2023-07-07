// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {StickerLib} from "../StickerLib.sol";
import {BasePrinter} from "../BasePrinter.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IPrinter} from "../interfaces/IPrinter.sol";

contract MockPrinter is BasePrinter {
    error InvalidSalt();
    error InvalidId();

    address public immutable ARTIST;
    uint256 public immutable MAX_ID;
    bytes8 public immutable SALT;

    constructor(address artist, uint8 maxId, bytes8 salt) {
        ARTIST = artist;
        MAX_ID = maxId;
        SALT = salt;
    }

    function onBeforePrint(
        address,
        uint256[] calldata ids,
        uint256[] calldata,
        bytes calldata
    )
        external
        view
        override
        returns (bytes4)
    {
        // require that salt matches what we're able to mint
        for (uint256 i = 0; i < ids.length; i++) {
            (, uint8 id, bytes8 salt,) = StickerLib.peel(ids[i]);
            if (salt != SALT) revert InvalidSalt();
            if (id > MAX_ID) revert InvalidId();
        }

        return IPrinter.onBeforePrint.selector;
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

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BasePrinter)
        returns (bool)
    {
        // forgefmt: disable-next-item
        return
            interfaceId == IPrinter.onBeforePrint.selector ||
            super.supportsInterface(interfaceId);
    }
}
