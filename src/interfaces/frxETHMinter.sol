// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IsfrxETH} from "./IsfrxETH.sol";

interface frxETHMinter {
    function frxETHToken() external returns (IERC20 frxETH);

    function sfrxETHToken() external returns (IsfrxETH sfrxETH);

    function submitAndDeposit(
        address recipient
    ) external payable returns (uint256 shares);
}
