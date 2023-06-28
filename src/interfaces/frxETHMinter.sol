// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IsfrxETH} from "./IsfrxETH.sol";

interface frxETHMinter {
    function sfrxETHToken() external returns (IsfrxETH sfrxETH);

    function submitAndDeposit(
        address recipient
    ) external payable returns (uint256 shares);
}
