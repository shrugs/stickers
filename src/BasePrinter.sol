// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IPrinter, IERC165} from "./interfaces/IPrinter.sol";
import {ERC165} from "openzeppelin/utils/introspection/ERC165.sol";

/**
 * @notice helpful base contract for Printers
 * @dev BasePrinter implements:
 *  - supportsInterface for IPrinter
 *  - stubs for hooks
 *
 * Inheritors implement:
 * - uri
 * - primarySaleInfo
 * - royaltyInfo
 * - hooks (enable by supportsInterface(IPrinter.[hook].selector))
 */
abstract contract BasePrinter is IPrinter, ERC165 {
    error NotImplemented();

    /**
     * @dev See {IPrinter-onBeforePrint}.
     */
    function onBeforePrint(
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    )
        external
        virtual
        returns (bytes4)
    {
        revert NotImplemented();
    }

    /**
     * @dev See {IPrinter-onAfterStick}.
     */
    function onAfterStick(
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    )
        external
        virtual
        returns (bytes4)
    {
        revert NotImplemented();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        // forgefmt: disable-next-item
        return
            interfaceId == type(IPrinter).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
