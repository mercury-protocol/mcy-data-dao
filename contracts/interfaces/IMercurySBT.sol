// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMercurySBT {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function membersCount() external view returns (uint256);

    function mint(address to) external;

    function revoke(uint256 tokenId) external;
}