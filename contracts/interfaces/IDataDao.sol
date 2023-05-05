// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../utils/Structs.sol";
import "./IMercurySBT.sol";

interface IDataDao {
    /// @dev Emitted when a admin is added to the DAO
    /// @param adminAddress: account address of the admin
    event AdminAdded(address adminAddress);

    /// @dev Emitted when a member is added to the DAO
    /// @param memberAddress: account address of the member
    event MemberAdded(address memberAddress);

    function grantMembership(address to) external;

    function revokeMembership(uint256 tokenId) external;

    function isMember(address user) external view returns (bool);

    function membershipCount() external view returns (uint256);

    function activePieceCids() external view returns (bytes[] memory);

    function distributeEarnings() external;

    function depositFil() external payable;

    function withdrawFil(uint256 amount) external;

    function sbt() external view returns (IMercurySBT);

    function createOrder(
        uint256 _price,
        uint256 _dataUnits,
        Structs.DataType calldata _dataType,
        bytes32 _dataHash
    ) external;

    function acceptBuyOrder(
        bytes32 _id,
        uint256 _units,
        bytes32 _dataHash
    ) external;

    function updateOrder(
        bytes32 _id,
        uint256 _price,
        uint256 _dataUnits,
        Structs.DataType calldata _dataType
    ) external;

    function cancelOrder(bytes32 _id) external;

    function setOrderActive(bytes32 _id, bool _isActive) external;
}
