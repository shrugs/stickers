// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {MerklePrinter} from "../src/examples/MerklePrinter.sol";
import {WithStickers} from "./helpers/WithStickers.sol";
import {StickerLib} from "../src/StickerLib.sol";

// TODO: catch NotImplemented for primarySaleInfo or royaltyInfo
contract MerklePrinterTest is Test, WithStickers {
    bytes32 ROOT = 0x02f70126543d894063566c3182d6d4a43a30d449e07e08ecdb786a52e6553597;
    address VALID = 0xC05D9575553dFf48e8b903852B98538a92729bb3;
    address INVALID = address(69);

    bytes32[] VALID_PROOF = [
        0x805dd5bb08e4b1ee0085bcb5f01097a764f935ea93acfddc5bd189634f963459,
        0xc2064123568ea31934a918492b330fb69b13364fc726a6570f80e51ba1a987c3,
        0x4c704c66be5c4e3b852b3bc66022e5cb56580ebde89ef1ff260722e52ecfb431,
        0xc915273b5c0fdc36e7498f7c9111bfddf22c330ca98370fdaf28536aa8fabe1c
    ];

    MerklePrinter merklePrinter;

    uint256[] ids = [StickerLib.attach(0, 0, 0, address(merklePrinter))];
    uint256[] amounts = [1];

    function setUp() public override {
        merklePrinter = new MerklePrinter(ROOT);
        super.setUp();
    }

    function test_validProof() public {
        _print(address(1), ids, amounts, abi.encode(VALID_PROOF));
        assertEq(stickers.balanceOf(address(1), 0), 1);
    }
}
