// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {Vault} from "../src/Vault.sol";

import {WithStickers} from "./helpers/WithStickers.sol";

contract VaultTest is Test, WithStickers {
    uint256[] EXAMPLE_IDS = [_tier(0), _tier(1), _tier(2), _tier(3), _tier(4)];
    uint256[] EXAMPLE_AMOUNTS = [1, 2, 3, 4, 5];

    function setUp() public override {
        super.setUp();
    }

    function test_stakingReward() public {
        _print(address(1), EXAMPLE_IDS, EXAMPLE_AMOUNTS, "");

        uint256 prev = _frxETHBalanceOf(address(vault));
        _simulateStakingRewards();
        assertGt(_frxETHBalanceOf(address(vault)), prev);
    }
}
