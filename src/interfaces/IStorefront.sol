// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IStickerPrinter} from "./IStickerPrinter.sol";

interface IStorefront {
    function printer(
        uint256 id
    ) external view returns (IStickerPrinter printer);
}
