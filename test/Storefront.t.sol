// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {Storefront} from "../src/Storefront.sol";
import {Stickers} from "../src/Stickers.sol";
import {Vault} from "../src/Vault.sol";
import {StickerLib} from "../src/StickerLib.sol";
import {frxETHMinter} from "../src/interfaces/frxETHMinter.sol";

contract StorefrontTest is Test {
    frxETHMinter MAINNET_MINTER = frxETHMinter(0xbAFA44EFE7901E04E39Dad13167D089C559c1138);

    Storefront storefront;
    Vault vault;
    Stickers stickers;

    uint256 BASE_DEPOSIT;

    uint256[] ids = [_tier(0), _tier(1), _tier(2), _tier(3), _tier(4)];
    uint256[] amounts = [1, 2, 3, 4, 5];

    address minter = address(1);

    function setUp() public {
        storefront = new Storefront(MAINNET_MINTER);
        stickers = storefront.$stickers();
        vault = storefront.$vault();
        BASE_DEPOSIT = storefront.BASE_DEPOSIT();
    }

    function test_printing() public {
        vm.deal(minter, 10 ether);
        vm.startPrank(minter);
        (uint256 amount,) = storefront.validateAndCalculateDeposit(ids, amounts);
        storefront.print{value: amount}(ids, amounts, "");
        vm.stopPrank();

        // the minter should have ids and amounts
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 balance = stickers.balanceOf(minter, ids[i]);
            assertEq(balance, amounts[i]);
        }

        // vault should expect to reserve that amount
        assertEq(vault.$reserve(), amount);
        // the vault should be able to redeem that amount of frxETH
        assertApproxEqAbs(_frxETHBalanceOfVault(), amount, BASE_DEPOSIT);
    }

    function test_calculateBackingAmount() public {
        (uint256 amount,) = storefront.validateAndCalculateDeposit(ids, amounts);
        assertEq(amount, 5.4321 ether);
    }

    function _frxETHBalanceOfVault() public returns (uint256) {
        return MAINNET_MINTER.sfrxETHToken().convertToAssets(
            MAINNET_MINTER.sfrxETHToken().balanceOf(address(vault))
        );
    }

    function _tier(uint8 tier) internal pure returns (uint256) {
        return StickerLib.attach(tier, 0, 0, address(0));
    }
}
