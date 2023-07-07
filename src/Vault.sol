// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {frxETHMinter} from "./interfaces/frxETHMinter.sol";
import {IsfrxETH} from "./interfaces/IsfrxETH.sol";

/**
 * @title Vault
 * @notice backs stickers with frxETH
 * @dev this vault should be owned by the Storefront, the contract with the authority to print
 * and burn stickers. It tracks its own $reserve of backing assets (frxETH) and enforces it with
 * an _invariant per-interaction.
 */
contract Vault is Owned {
    frxETHMinter public immutable $frxETHMinter;

    // TODO: allow withdrawl of surplus frxETH to distributor/dao by tracking reserve
    // TODO: align epochs w/ CRV?
    uint256 public $reserve;

    error WouldReduceReserve(uint256 expected, uint256 actual);

    constructor(frxETHMinter minter) Owned(msg.sender) {
        $frxETHMinter = minter;
    }

    function depositETH() external payable onlyOwner returns (uint256 shares) {
        shares = $frxETHMinter.submitAndDeposit{value: msg.value}(address(this));

        unchecked {
            $reserve += msg.value;
        }

        _invariant();
    }

    /// @dev deposit a specific amount of frxETH from `source` into sfrxETH
    function depositfrxETH(
        address from,
        uint256 amount
    )
        external
        onlyOwner
        returns (uint256 recieved)
    {
        IERC20 frxETH = $frxETHMinter.frxETHToken();
        IsfrxETH sfrxETH = $frxETHMinter.sfrxETHToken();

        // allow the minter to take our frxETH
        frxETH.approve(address($frxETHMinter), amount);

        // get the frxETH from the source
        frxETH.transferFrom(from, address(this), amount);

        // deposit
        frxETH.approve(address(sfrxETH), amount);
        recieved = sfrxETH.deposit(amount, address(this));
        // TODO: why this this check required?
        // https://github.com/FraxFinance/frxETH-public/blob/master/src/frxETHMinter.sol#L79
        require(recieved > 0, "No sfrxETH was returned");

        unchecked {
            $reserve += amount;
        }

        _invariant();
    }

    /// @dev withdraw a specific amount of frxETH from sfrxETH
    function withdrawfrxETH(
        address recipient,
        uint256 amount
    )
        external
        onlyOwner
        returns (uint256 shares)
    {
        // forgefmt: disable-next-item
        shares = $frxETHMinter
            .sfrxETHToken()
            .withdraw(amount, recipient, address(this));

        // TODO: make sure this can't underflow somehow?
        // could this contract own sfrxETH that it hasn't accounted for?
        unchecked {
            $reserve -= amount;
        }

        _invariant();
    }

    function _invariant() internal {
        // the vault invariant is that it can always redeem at least $reserve assets
        IsfrxETH sfrxETH = $frxETHMinter.sfrxETHToken();
        uint256 redeemable = sfrxETH.previewRedeem(sfrxETH.balanceOf(address(this)));

        if ($reserve < redeemable) return; // in the money

        // we can redeem fewer assets than we expect, but let's just see if it's a rounding error
        // redeemable assets are calculated with a mulDivDown, so this invariant needs to allow
        // for a small rounding error
        // TODO: see if this rounding error increases depending on how much is locked, or time or something
        uint256 delta = $reserve - redeemable; // cannot underflow because $reserve >= redeemable
        if (delta > 1) revert WouldReduceReserve($reserve, redeemable);
    }
}
