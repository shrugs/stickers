// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC165} from "openzeppelin/interfaces/IERC165.sol";
import {IERC2981} from "openzeppelin/interfaces/IERC2981.sol";

/**
 * @title IPrinter
 * @notice sticker implementation interface
 * @dev must implement uri, royaltyInfo
 * probably must implement onBeforePrint to check minting validity
 */
interface IPrinter is IERC165, IERC2981 {
    function onBeforePrint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    )
        external
        returns (bytes4);

    function onAfterStick(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    )
        external
        returns (bytes4);

    /**
     * @notice provide primarySale information to the caller
     * @dev similar to royaltyInfo
     */
    function primarySaleInfo(
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256 deposit
    )
        external
        view
        returns (address receiver, uint256 saleAmount);

    // IERC1155MetadataURI
    function uri(uint256 id) external view returns (string memory);
    // royaltyInfo via IERC2981
}
