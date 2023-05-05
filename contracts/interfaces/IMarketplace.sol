// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
@title Marketplace Interface 
@author Lajos Deme, Mercury Labs
@notice The Mercury Marketplace. It exposes two functions to accept data offers (buyer side) and to provide data for an order (seller).
 */
interface IMarketplace {
    event AcceptSellOrder(bytes32 indexed id, bytes32 indexed acceptanceId);
    event AcceptBuyOrder(bytes32 indexed id, bytes32 indexed acceptanceId);
    
    /** 
    @notice Accepts a sell order from a data seller.
    @dev It checks whether the buyer has enough deposits to pay.
    @dev Also checks whether the order has an operator who has valid attestation
    The operator confirms the data receival for a sell order by setting the data units fulfilled to the amount of data received.
    If the amount of data recived is equal to the amount given in the order, the order can be set to active.
    If it is active, then buyers can accept the sell order.
    @param _id The id of the Order to accept
    */
    function acceptSellOrder(bytes32 _id) external;

    /** 
    @notice Provides data for a buy order.
    @dev This creates a OrderAcceptance and sets the state to pending, and only change to accepted once operator confirmed the data receival.
    @param _id The id of the Order the user is providing data for.
    @param _units The units of data provided.
    */
    function acceptBuyOrder(bytes32 _id, uint256 _units, bytes32 _dataHash) external;
}