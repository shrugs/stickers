// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {MockPrinter} from "../src/mocks/MockPrinter.sol";
import {WithStickers} from "./helpers/WithStickers.sol";
import {StickerLib} from "../src/StickerLib.sol";

contract PrinterTest is Test, WithStickers {
    MockPrinter printer;

    uint8 MAX_TIER = 2;
    uint8 VALID_TIER = 0;
    uint8 MAX_ID = 100;
    uint8 VALID_ID = 1;
    bytes8 VALID_SALT = "hello";

    uint256[] amounts = [1];

    function setUp() public override {
        super.setUp();

        printer = new MockPrinter(ARTIST, MAX_TIER, MAX_ID, VALID_SALT);
    }

    function test_canPrintWithValidId() public {
        uint256[] memory ids =
            _ids(StickerLib.press(VALID_TIER, VALID_ID, VALID_SALT, address(printer)));
        _print(address(1), ids, amounts, "");
        assertEq(stickers.balanceOf(address(1), ids[0]), amounts[0]);
    }

    function test_cannotPrintWithInvalidTier() public {
        _assertCannotPrint(
            address(1),
            _ids(StickerLib.press(MAX_TIER + 1, VALID_ID, VALID_SALT, address(printer))),
            amounts,
            "",
            MockPrinter.InvalidTier.selector
        );
    }

    function test_cannotPrintWithInvalidId() public {
        _assertCannotPrint(
            address(1),
            _ids(StickerLib.press(VALID_TIER, MAX_ID + 1, VALID_SALT, address(printer))),
            amounts,
            "",
            MockPrinter.InvalidId.selector
        );
    }

    function test_cannotPrintWithInvalidSalt() public {
        _assertCannotPrint(
            address(1),
            _ids(StickerLib.press(VALID_TIER, VALID_ID, "invalid", address(printer))),
            amounts,
            "",
            MockPrinter.InvalidSalt.selector
        );
    }

    function _ids(uint256 tokenId) internal pure returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;
        return ids;
    }
}
