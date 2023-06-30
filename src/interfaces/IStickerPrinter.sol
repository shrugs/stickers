// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC2981} from "openzeppelin/interfaces/IERC2981.sol";

/**
 * @dev implements any logic
 */
interface IStickerPrinter is IERC2981 {
    // hooks
    // function onBeforeMint(uint256[] ids, uint256[] amounts, address to);

    function uri(uint256 id) external view returns (string memory);
    // royaltyInfo via IERC2981
}
