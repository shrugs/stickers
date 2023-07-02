// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20Permit} from "openzeppelin/token/ERC20/extensions/IERC20Permit.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {Vault} from "./Vault.sol";
import {Stickers} from "./Stickers.sol";
import {StickerLib} from "./StickerLib.sol";
import {frxETHMinter} from "./interfaces/frxETHMinter.sol";
import {IStickerPrinter} from "./interfaces/IStickerPrinter.sol";

contract Storefront {
    using FixedPointMathLib for uint256;

    Vault public immutable $vault;
    Stickers public immutable $stickers;

    // the base deposit for a tier 0 sticker
    uint256 public constant BASE_DEPOSIT = 0.0001 ether;

    // the artist's share as a WAD percentage
    uint256 public constant ARTIST_SHARE = 20e16; // 20%

    error InvalidAmountsLength();
    error OnlySinglePrinter();
    error InvalidTier();

    constructor(frxETHMinter minter) {
        $vault = new Vault(minter);
        $stickers = new Stickers();
    }

    function printWithPermit(
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes calldata data,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        // forgefmt: disable-next-item
        IERC20Permit(address($vault.$frxETHMinter().frxETHToken()))
            .permit(msg.sender, address(this), amount, deadline, v, r, s);

        print(ids, amounts, data);
    }

    function print(
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes calldata data
    )
        public
        payable
    {
        (uint256 deposit, address printer) = validateAndCalculateDeposit(ids, amounts);

        // TODO: calculate + pay artist share by consulting printer.royaltyInfo
        // (address receiver, ) = IStickerPrinter(printer).royaltyInfo(0, 0);
        // SafeTransferLib.transferETH()

        _deposit(msg.sender, deposit);
        _print(msg.sender, ids, amounts, printer, data);
    }

    function _deposit(address from, uint256 amount) internal {
        if (msg.value != 0) {
            // ETH
            require(msg.value == amount, "msg.value != totalBacked");
            $vault.depositETH{value: msg.value}();
        } else {
            // frxETH
            // amount is checked in transfer
            $vault.depositfrxETH(from, amount);
        }
    }

    function _print(
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        address printer,
        bytes calldata data
    )
        internal
    {
        // TODO: can print hook
        // TODO: include `data` to power merkle allowlists, etc
        // IStickerPrinter(printer).beforePrint(recipient, ids, amounts, data);

        // mint the ids to the recipient
        // mvp: mint directly rather than communicating over the bridge
        // TODO: this calls the 1155 batchMint callback, ensure no reentrancy bugs lol
        $stickers.mint(recipient, ids, amounts);
    }

    function calculateArtistShare(uint256 deposit) public pure returns (uint256 share) {
        share = deposit.mulWadDown(ARTIST_SHARE);
    }

    function validateAndCalculateDeposit(
        uint256[] memory ids,
        uint256[] memory amounts
    )
        public
        pure
        returns (uint256 deposit, address printer)
    {
        // invariant: ids and amounts must be equal length
        if (ids.length != amounts.length) revert InvalidAmountsLength();

        uint256 len = ids.length;
        for (uint256 i = 0; i < len;) {
            (uint8 tier,,, address _printer) = StickerLib.peel(ids[i]);

            // invariant: all ids must have the same printer
            if (printer == address(0)) {
                printer = _printer;
            } else if (_printer != printer) {
                revert OnlySinglePrinter();
            }

            // invariant: the highest tier is 4
            if (tier > 4) revert InvalidTier();

            unchecked {
                deposit += amounts[i] * BASE_DEPOSIT * (10 ** tier);
                i++;
            }
        }
    }
}
