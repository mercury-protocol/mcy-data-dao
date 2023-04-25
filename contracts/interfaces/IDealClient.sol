// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../utils/Structs.sol";

interface IDealClient {
    function makeDealProposal(Structs.DealRequest calldata deal) external;
}