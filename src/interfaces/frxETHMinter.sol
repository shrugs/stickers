// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface frxETHMinter {
    function sfrxETHToken() public returns (IsfrxETH sfrxETH);

    function submitAndDeposit(
        address recipient
    ) external payable returns (uint256 shares);
}
