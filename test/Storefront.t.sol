// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {WithStickers} from "./helpers/WithStickers.sol";
import {SigUtils} from "./helpers/SigUtils.sol";
import {IERC20Permit} from "openzeppelin/token/ERC20/extensions/IERC20Permit.sol";

contract StorefrontTest is Test, WithStickers {
    uint256[] EXAMPLE_IDS = [_tier(0), _tier(1), _tier(2), _tier(3), _tier(4)];
    uint256[] EXAMPLE_AMOUNTS = [1, 2, 3, 4, 5];
    uint256 EXPECTED_BACKING_AMOUNT = 5.4321 ether;

    address minter = address(1);

    function setUp() public override {
        super.setUp();
    }

    function test_calculateBackingAmount() public {
        (uint256 amount,) = storefront.validateAndCalculateDeposit(EXAMPLE_IDS, EXAMPLE_AMOUNTS);
        assertEq(amount, EXPECTED_BACKING_AMOUNT);
    }

    function test_printingExample() public {
        uint256 artistPrevBalance = ARTIST.balance;
        (, uint256 deposit, uint256 primarySaleAmount) =
            _print(minter, EXAMPLE_IDS, EXAMPLE_AMOUNTS, "");

        // the minter should have ids and amounts
        for (uint256 i = 0; i < EXAMPLE_IDS.length; i++) {
            uint256 balance = stickers.balanceOf(minter, EXAMPLE_IDS[i]);
            assertEq(balance, EXAMPLE_AMOUNTS[i]);
        }

        _assertVaultReserve(deposit);

        // artist received correct sale amount
        assertEq(stdMath.delta(artistPrevBalance, ARTIST.balance), primarySaleAmount);
    }

    function test_printingMany() public {
        uint256[] memory _ids = new uint256[](1);
        _ids[0] = _tier(0);

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = 100_000;

        (, uint256 deposit,) = _print(minter, _ids, _amounts, "");
        _assertVaultReserve(deposit);
    }

    function test_printWithfrxETH() public {
        // calculate needed amount of frxETH
        (uint256 total,,) =
            storefront.validateAndCalculatePrintingCost(EXAMPLE_IDS, EXAMPLE_AMOUNTS);

        // give frxETH
        deal(address(MAINNET_MINTER.frxETHToken()), minter, total);

        // approve storefront
        vm.startPrank(minter);
        MAINNET_MINTER.frxETHToken().approve(address(storefront), total);

        // print the stickers with frxETH
        storefront.print(EXAMPLE_IDS, EXAMPLE_AMOUNTS, "");
        vm.stopPrank();
    }

    function test_printWithPermit() public {
        uint256 ownerPrivateKey = 0xA11CE;
        address owner = vm.addr(ownerPrivateKey);

        IERC20Permit frxETH = IERC20Permit(address(MAINNET_MINTER.frxETHToken()));

        // calculate needed amount of frxETH
        (uint256 total,,) =
            storefront.validateAndCalculatePrintingCost(EXAMPLE_IDS, EXAMPLE_AMOUNTS);

        // deal owner that frxETH
        deal(address(frxETH), owner, total);

        // generate sig
        SigUtils sigUtils = new SigUtils(frxETH.DOMAIN_SEPARATOR());
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: address(storefront),
            value: total,
            nonce: frxETH.nonces(owner),
            deadline: block.timestamp
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        vm.prank(owner);
        // forgefmt: disable-next-item
        storefront.printWithPermit(
            EXAMPLE_IDS, EXAMPLE_AMOUNTS, "", total,
            permit.deadline, v, r, s
        );
    }
}
