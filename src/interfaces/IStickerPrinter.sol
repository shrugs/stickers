// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IStickerPrinter {
    function uri(uint256 id) external view returns (string memory);
}
