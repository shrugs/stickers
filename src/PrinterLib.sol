// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC165Checker} from "openzeppelin/utils/introspection/ERC165Checker.sol";
import {IPrinter} from "./interfaces/IPrinter.sol";

library PrinterLib {
    using ERC165Checker for address;

    function shouldCallonBeforePrint(address printer) public view returns (bool) {
        return printer.supportsInterface(IPrinter.onBeforePrint.selector);
    }

    /// @notice checks whether a given contract supportsInterface(IPrinter)
    function validate(address printer) public view returns (bool) {
        return printer.supportsInterface(type(IPrinter).interfaceId);
    }
}
