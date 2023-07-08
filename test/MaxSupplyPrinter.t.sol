// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {MaxSupplyPrinter} from "../src/examples/MaxSupplyPrinter.sol";
import {WithStickers} from "./helpers/WithStickers.sol";
import {StickerLib} from "../src/StickerLib.sol";

contract MaxSupplyPrinterTest is Test, WithStickers {
    address minter = address(1);

    MaxSupplyPrinter printer;
    uint256 MAX_SUPPLY = 10;
    uint256[] ids;
    uint256[] amounts;

    function setUp() public override {
        super.setUp();

        printer = new MaxSupplyPrinter(ARTIST, MAX_SUPPLY);
        ids = [StickerLib.press(0, 0, "", address(printer))];
    }

    function test_canPrint() public {
        amounts = [5];
        _print(minter, ids, amounts, "");
        assertEq(stickers.balanceOf(minter, ids[0]), 5);
    }

    function test_canPrintMultiple() public {
        amounts = [1];
        _print(minter, ids, amounts, "");
        _print(minter, ids, amounts, "");
        _print(minter, ids, amounts, "");
        _print(minter, ids, amounts, "");
        _print(minter, ids, amounts, "");
        assertEq(stickers.balanceOf(minter, ids[0]), 5);
    }

    function test_canPrintMaxSupply() public {
        amounts = [MAX_SUPPLY];
        _print(minter, ids, amounts, "");
    }

    function testRevert_overMaxSupply() public {
        amounts = [MAX_SUPPLY + 1];
        (uint256 total,,) = storefront.validateAndCalculatePrintingCost(ids, amounts);

        vm.expectRevert(MaxSupplyPrinter.MaxSupplyReached.selector);
        _printWithValue(minter, ids, amounts, "", total);
    }

    function test_priceIncreasesPerPrint() public {
        amounts = [1];
        (uint256 firstTotal,, uint256 firstPrimarySaleAmount) =
            storefront.validateAndCalculatePrintingCost(ids, amounts);

        _printWithValue(minter, ids, amounts, "", firstTotal);

        (,, uint256 secondPrimarySaleAmount) =
            storefront.validateAndCalculatePrintingCost(ids, amounts);

        assertGt(secondPrimarySaleAmount, firstPrimarySaleAmount);
    }
}
