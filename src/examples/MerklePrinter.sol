// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";
import {Base64} from "openzeppelin/utils/Base64.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {StickerLib} from "../StickerLib.sol";
import {BasePrinter} from "../BasePrinter.sol";

import {IPrinter} from "../interfaces/IPrinter.sol";

contract MerklePrinter is BasePrinter {
    error InvalidProof();

    address public constant ARTIST = address(69);
    bytes32 public immutable ROOT;

    constructor(bytes32 root) {
        ROOT = root;
    }

    function onBeforePrint(
        address to,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata data
    )
        external
        view
        override
        returns (bytes4)
    {
        (bytes32[] memory proof) = abi.decode(data, (bytes32[]));
        bool isValid = MerkleProof.verify(proof, ROOT, keccak256(abi.encodePacked(to)));
        if (!isValid) revert InvalidProof();

        return IPrinter.onBeforePrint.selector;
    }

    function primarySaleInfo(
        uint256[] memory,
        uint256[] memory,
        uint256 deposit
    )
        external
        pure
        returns (address receiver, uint256 saleAmount)
    {
        // 20% on top of deposit for primary printing sales
        return (ARTIST, FixedPointMathLib.mulWadUp(deposit, 20e16));
    }

    function royaltyInfo(
        uint256,
        uint256 salePrice
    )
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        // 5% royalties on secondary sales
        return (ARTIST, FixedPointMathLib.mulWadUp(salePrice, 5e16));
    }

    function uri(uint256 tokenId) external pure returns (string memory) {
        (, uint8 id, bytes8 salt,) = StickerLib.peel(tokenId);
        return string.concat(
            "https://example.com/", string(abi.encodePacked(salt)), "/", LibString.toString(id)
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
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
            super.supportsInterface(interfaceId);
    }
}
