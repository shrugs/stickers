// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IERC20Permit} from "openzeppelin/token/ERC20/extensions/IERC20Permit.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {Vault} from "./Vault.sol";
import {Stickers} from "./Stickers.sol";
import {StickerLib} from "./StickerLib.sol";
import {PrinterLib} from "./PrinterLib.sol";
import {frxETHMinter} from "./interfaces/frxETHMinter.sol";
import {IPrinter} from "./interfaces/IPrinter.sol";

contract Storefront {
    Vault public immutable $vault;
    Stickers public immutable $stickers;

    // the base deposit for a tier 0 sticker
    uint8 public constant HIGHEST_TIER = 4;
    uint256 public constant BASE_DEPOSIT = 0.0001 ether;

    error InvalidPrinter(address printer);
    error InvalidAmountsLength(uint256 idsLength, uint256 amountsLength);
    error OnlySinglePrinter(address expected, address received);
    error InvalidTier(uint8 tier);

    constructor(frxETHMinter minter) {
        $vault = new Vault(minter);
        $stickers = new Stickers();
    }

    // printing

    function printWithPermit(
        uint256[] calldata ids,
        uint256[] calldata amounts,
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
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    )
        public
        payable
    {
        // tabulate deposit amount
        (uint256 deposit, address printer) = validateAndCalculateDeposit(ids, amounts);

        // calculate artist primary sale amount
        (address receiver, uint256 primarySaleAmount) =
            IPrinter(printer).primarySaleInfo(ids, amounts, deposit);

        // forward primary sale amount
        _sustain(msg.sender, receiver, primarySaleAmount);

        // deposit the backing frxETH
        _deposit(msg.sender, deposit);

        // print the requested stickers
        _print(msg.sender, ids, amounts, data);
    }

    // sticking

    /**
     * @notice burns `amounts` of `ids`, redeeming the reserved frxETH
     * @dev in v0.1 this is simply called by the user wishing to burn
     * in v1.0, this would be announced by a trusted L2 contract
     */
    function stick(uint256[] calldata ids, uint256[] calldata amounts) public {
        (uint256 deposit,) = validateAndCalculateDeposit(ids, amounts);
        $stickers.burn(msg.sender, ids, amounts);
        $vault.withdrawfrxETH(msg.sender, deposit);
    }

    // validation / calculations

    function validateAndCalculatePrintingCost(
        uint256[] calldata ids,
        uint256[] calldata amounts
    )
        public
        view
        returns (uint256 total, uint256 deposit, uint256 primarySaleAmount)
    {
        // tabulate deposit amount
        address printer;
        (deposit, printer) = validateAndCalculateDeposit(ids, amounts);

        // calculate artist primary sale amount
        (, primarySaleAmount) = IPrinter(printer).primarySaleInfo(ids, amounts, deposit);

        unchecked {
            total = deposit + primarySaleAmount;
        }
    }

    function validateAndCalculateDeposit(
        uint256[] calldata ids,
        uint256[] calldata amounts
    )
        public
        view
        returns (uint256 deposit, address printer)
    {
        // invariant: ids and amounts must be equal length and not 0
        // (could remove the 0 check but peace of mind is worth it)
        if (ids.length != amounts.length || ids.length == 0) {
            revert InvalidAmountsLength(ids.length, amounts.length);
        }

        uint256 len = ids.length;
        for (uint256 i = 0; i < len;) {
            (uint8 tier,,, address _printer) = StickerLib.peel(ids[i]);

            // invariant: all ids must have the same printer
            if (printer == address(0)) {
                printer = _printer;
            } else if (_printer != printer) {
                revert OnlySinglePrinter(printer, _printer);
            }

            // invariant: check highest tier
            if (tier > HIGHEST_TIER) revert InvalidTier(tier);

            unchecked {
                deposit += amounts[i] * BASE_DEPOSIT * (10 ** tier);
                i++;
            }
        }

        // invariant: printer must identify as printer
        if (!PrinterLib.validate(printer)) revert InvalidPrinter(printer);
    }

    // Internals

    function _sustain(address sender, address receiver, uint256 amount) internal {
        if (msg.value != 0) {
            // ETH
            SafeTransferLib.safeTransferETH(receiver, amount);
        } else {
            // frxETH
            // no need to check return value, frxETH is a reverting ERC20
            $vault.$frxETHMinter().frxETHToken().transferFrom(sender, receiver, amount);
        }
    }

    function _deposit(address from, uint256 amount) internal {
        if (msg.value != 0) {
            // ETH
            $vault.depositETH{value: amount}();
        } else {
            // frxETH
            IERC20 frxETHToken = $vault.$frxETHMinter().frxETHToken();
            frxETHToken.transferFrom(from, address(this), amount);
            frxETHToken.approve(address($vault), amount);
            $vault.depositfrxETH(address(this), amount);
        }
    }

    function _print(
        address recipient,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    )
        internal
    {
        // TODO: this calls the 1155 batchMint callback, ensure no reentrancy bugs lol
        // mint the ids to the recipient
        $stickers.mint(recipient, ids, amounts, data);
    }
}
