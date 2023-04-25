// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../utils/Structs.sol";

/**
@title Data Manager Interface
@author Lajos Deme, Mercury Labs
@notice The data manager is responsible for keeping track of each buy/sell data offer.
 */
interface IDataManager {
    /**
    @dev Creates a new data sale item on the marketplace.
    @param _price The price in MCY offered/asked for the data.
    @param _dataUnits The units of data needed/offered.
    @param _dataType The data type the data sale item is about
    @param _buy Wether it is a buy/sale offer.
     */
    function createOrder(
        uint256 _price,
        uint256 _dataUnits,
        Structs.DataType calldata _dataType,
        bool _buy,
        bytes32 _dataHash
    ) external returns (bytes32 id);

    /**
    @dev Upodates an existing data sale item on the marketplace.
    @param _id The id of the data sale item.
    @param _price The price in MCY offered/asked for the data.
    @param _dataUnits The units of data needed/offered.
    @param _dataType The data type the data sale item is about
     */
    function updateOrder(
        bytes32 _id,
        uint256 _price,
        uint256 _dataUnits,
        Structs.DataType calldata _dataType
    ) external;

    /**
    @dev Cancels a data sale item that is not already fulfilled.
    @param _id The id of the data sale item to be cancelled.
     */
    function cancelOrder(bytes32 _id) external;

    /**
    @dev Sets the data sale item state to active/inactive.
    Callable by the creator.
    @param _id The id of the data sale item.
    @param _isActive The new state of the data sale item.
     */
    function setOrderActive(bytes32 _id, bool _isActive) external;
}