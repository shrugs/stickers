// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {StickerLib} from "../StickerLib.sol";
import {BasePrinter} from "../BasePrinter.sol";

import {IPrinter} from "../interfaces/IPrinter.sol";

/**
 * @dev allows any sticker to be printed, but tracks maximum global supply of them and charges more
 * per sticker.
 * you could track per sticker id, or per-tier, whatever you want
 */
contract MaxSupplyPrinter is BasePrinter {
    error MaxSupplyReached();

    address public immutable ARTIST;
    uint256 public immutable MAX_SUPPLY;

    uint256 public constant INCREMENT = 0.1 ether;

    uint256 public $supply;

    constructor(address artist, uint256 maxSupply) {
        ARTIST = artist;
        MAX_SUPPLY = maxSupply;
    }

    function onBeforePrint(
        address,
        uint256[] calldata,
        uint256[] calldata amounts,
        bytes calldata
    )
        external
        override
        returns (bytes4)
    {
        unchecked {
            $supply += _sum(amounts);
        }

        if ($supply > MAX_SUPPLY) revert MaxSupplyReached();

        return IPrinter.onBeforePrint.selector;
    }

    function onAfterStick(
        address,
        uint256[] calldata,
        uint256[] calldata amounts,
        bytes calldata
    )
        external
        override
        returns (bytes4)
    {
        unchecked {
            $supply -= _sum(amounts);
        }

        return IPrinter.onAfterStick.selector;
    }

    function primarySaleInfo(
        uint256[] calldata,
        uint256[] calldata amounts,
        uint256
    )
        external
        view
        returns (address, uint256)
    {
        // one would use a LinearCurve type thing here but i'm not that mathy
        // but this illustrates the point well enough
        return (ARTIST, $supply * INCREMENT * _sum(amounts));
    }

    function royaltyInfo(uint256, uint256) external view virtual returns (address, uint256) {
        return (ARTIST, 0);
    }

    function uri(uint256) external pure returns (string memory) {
        return "";
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

    function _sum(uint256[] calldata amounts) internal pure returns (uint256 sum) {
        uint256 len = amounts.length;
        for (uint256 i = 0; i < len;) {
            unchecked {
                sum += amounts[i];
                i++;
            }
        }
    }
}
