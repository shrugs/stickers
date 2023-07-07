// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library StickerLib {
    /// @notice separate `tokenId` into `tier`, `id`, `salt`, and `printer`
    function peel(uint256 tokenId)
        public
        pure
        returns (uint8 tier, uint8 id, bytes8 salt, address printer)
    {
        // forgefmt: disable-next-item
        return (
            uint8(tokenId),
            uint8(tokenId >> 8),
            bytes8(uint64(tokenId >> 16)),
            address(uint160(tokenId >> 80))
        );
    }

    /// @notice combine `tier`, `id`, `salt`, and `printer` into `tokenId`
    function attach(
        uint8 tier,
        uint8 id,
        bytes8 salt,
        address printer
    )
        public
        pure
        returns (uint256 tokenId)
    {
        // forgefmt: disable-next-item
        return
            uint256(tier) |
            (uint256(id) << 8) |
            (uint256(uint64(salt)) << 16) |
            (uint256(uint160(printer)) << 80);
    }
}
