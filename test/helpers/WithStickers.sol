// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {StickerLib} from "../../src/StickerLib.sol";
import {Storefront} from "../../src/Storefront.sol";
import {Stickers} from "../../src/Stickers.sol";
import {Vault} from "../../src/Vault.sol";

import {MinimalPrinter} from "../../src/examples/MinimalPrinter.sol";

import {IPrinter} from "../../src/interfaces/IPrinter.sol";
import {frxETHMinter} from "../../src/interfaces/frxETHMinter.sol";

abstract contract WithStickers is Test {
    address internal ARTIST = address(0xdeaf);

    IPrinter internal MINIMAL_PRINTER = new MinimalPrinter(ARTIST);
    frxETHMinter internal MAINNET_MINTER = frxETHMinter(0xbAFA44EFE7901E04E39Dad13167D089C559c1138);

    Storefront internal storefront;
    Vault internal vault;
    Stickers internal stickers;

    function setUp() public virtual {
        storefront = new Storefront(MAINNET_MINTER);
        stickers = storefront.$stickers();
        vault = storefront.$vault();
    }

    /// @notice generates a tokenId with a specified tier and
    function _tier(uint8 tier) internal view returns (uint256) {
        return StickerLib.attach(tier, 1, "salt", address(MINIMAL_PRINTER));
    }

    function _print(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        returns (uint256 total, uint256 deposit, uint256 primarySaleAmount)
    {
        (total, deposit, primarySaleAmount) =
            storefront.validateAndCalculatePrintingCost(ids, amounts);
        _printWithValue(to, ids, amounts, data, total);
    }

    function _printWithValue(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data,
        uint256 value
    )
        internal
    {
        vm.deal(to, value);
        vm.prank(to);
        storefront.print{value: value}(ids, amounts, data);
    }

    function _assertCannotPrint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data,
        bytes4 selector
    )
        internal
    {
        (uint256 total,,) = storefront.validateAndCalculatePrintingCost(ids, amounts);
        vm.expectRevert(selector);
        _printWithValue(to, ids, amounts, data, total);
    }

    function _assertVaultReserve(uint256 amount) internal {
        // vault should expect to reserve that amount
        assertEq(vault.$reserve(), amount);

        // the vault should be able to redeem that amount of frxETH (_invariant checks this but...)
        assertApproxEqAbs(_frxETHBalanceOf(address(vault)), amount, 0.0001 ether);
    }

    function _frxETHBalanceOf(address owner) internal returns (uint256) {
        return MAINNET_MINTER.sfrxETHToken().previewRedeem(
            MAINNET_MINTER.sfrxETHToken().balanceOf(owner)
        );
    }

    /// @dev simulates staking rewards by depositing some frxETH and fast-forwarding to
    /// the end of the reward cycle
    function _simulateStakingRewards() internal {
        deal(address(MAINNET_MINTER.frxETHToken()), address(MAINNET_MINTER.sfrxETHToken()), 1 ether);
        vm.warp(MAINNET_MINTER.sfrxETHToken().rewardsCycleEnd());
    }
}
