// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMercurySBT {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function membersCount() external view returns (uint256);

    function mint(address to) external;

    function revoke(uint256 tokenId) external;
}