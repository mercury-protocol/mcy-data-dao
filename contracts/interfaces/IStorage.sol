// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStorage {
    function filDeposits(address addr) external view returns (uint256);
    function setFilDeposit(address user, uint256 amount) external;
    function getActiveCids() external view returns (string[] memory);
    function getActiveCidsLength() external view returns (uint256);
    function activateCid(bytes calldata pieceCid) external;
}