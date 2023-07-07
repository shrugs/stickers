// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {MerklePrinter} from "../src/examples/MerklePrinter.sol";
import {WithStickers} from "./helpers/WithStickers.sol";
import {StickerLib} from "../src/StickerLib.sol";

import {Merkle} from "murky/Merkle.sol";

contract MerklePrinterTest is Test, WithStickers {
    MerklePrinter merklePrinter;

    bytes32[] proof;
    uint256[] ids;
    uint256[] amounts = [1];

    function setUp() public override {
        super.setUp();

        Merkle m = new Merkle();
        bytes32[] memory data = new bytes32[](4);
        data[0] = keccak256(abi.encodePacked(address(1)));
        data[1] = keccak256(abi.encodePacked(address(2)));
        data[2] = keccak256(abi.encodePacked(address(3)));
        data[3] = keccak256(abi.encodePacked(address(4)));

        bytes32 root = m.getRoot(data);
        proof = m.getProof(data, 0);

        merklePrinter = new MerklePrinter(root);
        ids = [StickerLib.attach(0, 1, 0, address(merklePrinter))];
    }

    function test_canPrintValidProof() public {
        _print(address(1), ids, amounts, abi.encode(proof));
        assertEq(stickers.balanceOf(address(1), ids[0]), 1);
    }

    function test_cannotPrintInvalidProof() public {
        (uint256 total,,) = storefront.validateAndCalculatePrintingCost(ids, amounts);
        vm.expectRevert(MerklePrinter.InvalidProof.selector);
        _printWithValue(address(2), ids, amounts, abi.encode(proof), total);
    }
}
