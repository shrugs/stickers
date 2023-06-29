// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {frxETHMinter} from "./interfaces/frxETHMinter.sol";
import {IsfrxETH} from "./interfaces/IsfrxETH.sol";

/// @title Vault that backs stickers with frxETH
/** @dev this vault should be owned by the Storefront, the contract with the authority to print
    and burn stickers.

    TODO: allow withdrawl of surplus frxETH to distributor/dao
 */
contract Vault is Owned {
    frxETHMinter public immutable $frxETHMinter;

    uint256 public totalReserve;

    constructor(frxETHMinter minter) Owned(msg.sender) {
        $frxETHMinter = minter;
    }

    function depositETH() external payable onlyOwner returns (uint256 shares) {
        return $frxETHMinter.submitAndDeposit(address(this));
    }

    function depositfrxETH(
        address from,
        uint256 amount
    ) external onlyOwner returns (uint256 recieved) {
        IERC20 frxETH = $frxETHMinter.frxETHToken();
        IsfrxETH sfrxETH = $frxETHMinter.sfrxETHToken();

        // allow the minter to take our frxETH
        frxETH.approve(address($frxETHMinter), amount);

        // get the frxETH from the printer
        frxETH.transferFrom(from, address(this), amount);

        // deposit
        frxETH.approve(address(sfrxETH), amount);
        recieved = sfrxETH.deposit(amount, address(this));
        // TODO: why this this check required?
        require(recieved > 0, "No sfrxETH was returned");
    }

    function withdrawfrxETH(
        address recipient,
        uint256 amount
    ) external onlyOwner returns (uint256 shares) {
        // prettier-ignore
        return $frxETHMinter
            .sfrxETHToken()
            .withdraw(amount, recipient, address(this));
    }
}
