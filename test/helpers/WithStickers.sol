// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {StickerLib} from "../../src/StickerLib.sol";
import {Storefront} from "../../src/Storefront.sol";
import {Stickers} from "../../src/Stickers.sol";
import {Vault} from "../../src/Vault.sol";

import {frxETHMinter} from "../../src/interfaces/frxETHMinter.sol";

abstract contract WithStickers is Test {
    frxETHMinter public MAINNET_MINTER = frxETHMinter(0xbAFA44EFE7901E04E39Dad13167D089C559c1138);

    Storefront storefront;
    Vault vault;
    Stickers stickers;

    function setUp() public virtual {
        storefront = new Storefront(MAINNET_MINTER);
        stickers = storefront.$stickers();
        vault = storefront.$vault();
    }

    function _tier(uint8 tier) internal pure returns (uint256) {
        return StickerLib.attach(tier, 0, 0, address(0));
    }

    function _print(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        returns (uint256 amount)
    {
        (amount,) = storefront.validateAndCalculateDeposit(ids, amounts);
        vm.deal(from, amount);
        vm.prank(from);
        storefront.print{value: amount}(ids, amounts, data);
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

    /// @dev simulates staking rewards by depositing some frxETH and fast-forwarding to the end of the reward cycle
    function _simulateStakingRewards() internal {
        deal(address(MAINNET_MINTER.frxETHToken()), address(MAINNET_MINTER.sfrxETHToken()), 1 ether);
        vm.warp(MAINNET_MINTER.sfrxETHToken().rewardsCycleEnd());
    }
}
