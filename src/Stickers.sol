// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {IStorefront} from "./interfaces/IStorefront.sol";

/** @dev the `owner` for mvp sake is the storefront but in reality will be a StickerMinter
    contract on the L2 which is in communication with the Storefront
 */
contract Stickers is ERC1155, Owned {
    constructor() Owned(msg.sender) {
        //
    }

    function uri(
        uint256 id
    ) public view virtual override returns (string memory) {
        // TODO: proxy this tokenURI to mainnet
        // https://github.com/OpenZeppelin/cairo-contracts/discussions/28
        return IStorefront(owner).printer(id).uri(id);
    }
}
