// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {StickerLib} from "../StickerLib.sol";
import {BasePrinter} from "../BasePrinter.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IPrinter} from "../interfaces/IPrinter.sol";

contract MockPrinter is BasePrinter {
    event Printed(address to, uint256[] ids, uint256[] amounts, bytes data);
    event Stuck(address from, uint256[] ids, uint256[] amounts, bytes data);

    error InvalidTier();
    error InvalidId();
    error InvalidSalt();

    address public immutable ARTIST;
    uint8 public immutable MAX_TIER;
    uint8 public immutable MAX_ID;
    bytes8 public immutable SALT;

    constructor(address artist, uint8 maxTier, uint8 maxId, bytes8 salt) {
        ARTIST = artist;
        MAX_TIER = maxTier;
        MAX_ID = maxId;
        SALT = salt;
    }

    function onBeforePrint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    )
        external
        override
        returns (bytes4)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            (uint8 tier, uint8 id, bytes8 salt,) = StickerLib.peel(ids[i]);

            // require that tier is in range we support
            if (tier > MAX_TIER) revert InvalidTier();

            // require that id is in range we support
            if (id > MAX_ID) revert InvalidId();

            // require that salt matches what we're able to mint
            if (salt != SALT) revert InvalidSalt();
        }

        emit Printed(to, ids, amounts, data);

        return IPrinter.onBeforePrint.selector;
    }

    function onAfterStick(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    )
        external
        override
        returns (bytes4)
    {
        emit Stuck(from, ids, amounts, data);

        return IPrinter.onAfterStick.selector;
    }

    function primarySaleInfo(
        uint256[] calldata,
        uint256[] calldata,
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
            interfaceId == IPrinter.onAfterStick.selector ||
            super.supportsInterface(interfaceId);
    }
}
