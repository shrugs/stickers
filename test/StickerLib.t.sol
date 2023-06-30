// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {StickerLib} from "../src/StickerLib.sol";

contract CitiTest is Test {
    function test_zeros() public {
        _assertPeel(0, 0, 0, 0, address(0));
    }

    function test_ones() public {
        _assertPeel(
            type(uint256).max,
            type(uint8).max,
            type(uint8).max,
            bytes8(type(uint64).max),
            address(type(uint160).max)
        );
    }

    function test_attachThenPeel() public {
        uint8 tier = 1;
        uint8 id = 1;
        bytes8 salt = "hello";
        address printer = address(1);

        uint256 tokenId = StickerLib.attach(tier, id, salt, printer);
        _assertPeel(tokenId, tier, id, salt, printer);
    }

    function _assertPeel(
        uint256 tokenId,
        uint8 tier,
        uint8 id,
        bytes8 salt,
        address printer
    ) internal {
        (uint8 _tier, uint8 _id, bytes8 _salt, address _printer) = StickerLib
            .peel(tokenId);
        assertEq(_tier, tier);
        assertEq(_id, id);
        assertEq(_salt, salt);
        assertEq(_printer, printer);
    }
}
