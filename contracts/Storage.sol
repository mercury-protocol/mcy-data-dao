// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {CommonTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import {MarketTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";
import {FilAddresses} from "@zondax/filecoin-solidity/contracts/v0.8/utils/FilAddresses.sol";
import {MarketCBOR} from "@zondax/filecoin-solidity/contracts/v0.8/cbor/MarketCbor.sol";
import "./utils/Structs.sol";
import "./utils/Enums.sol";
import "./utils/Utils.sol";

contract Storage {
    mapping(bytes32 => Structs.RequestIdx) public dealRequestIdx; // contract deal id -> deal index
    Structs.DealRequest[] public dealRequests;

    mapping(bytes => Structs.RequestId) public pieceRequests; // commP -> dealProposalID
    mapping(bytes => Structs.ProviderSet) public pieceProviders; // commP -> provider
    mapping(bytes => uint64) public pieceDeals; // commP -> deal ID
    mapping(bytes => Status) public pieceStatus;

    mapping(address => uint256) public filDeposits;

    address client;
    address dao;

    modifier authorize() {
        require(msg.sender == client || msg.sender == dao, "Unauthorized");
        _;
    }

    function setAuth(address _client, address _dao) external {
        require(client == address(0) && dao == address(0), "Already set");
        client = _client;
        dao = _dao;
    }

    bytes[] activeCids;
    function getProviderSet(
        bytes calldata cid
    ) public view returns (Structs.ProviderSet memory) {
        return pieceProviders[cid];
    }

    function getProposalIdSet(
        bytes calldata cid
    ) public view returns (Structs.RequestId memory) {
        return pieceRequests[cid];
    }

    function dealsLength() public view returns (uint256) {
        return dealRequests.length;
    }

    function getDealByIndex(
        uint256 index
    ) public view returns (Structs.DealRequest memory) {
        return dealRequests[index];
    }

    // helper function to get deal request based from id
    function getDealRequest(
        bytes32 requestId
    ) public view returns (Structs.DealRequest memory) {
        Structs.RequestIdx memory ri = dealRequestIdx[requestId];
        require(ri.valid, "proposalId not available");
        return dealRequests[ri.idx];
    }

    function getDealRequestsLength() external view returns (uint256) {
        return dealRequests.length;
    }

    function addDealRequest(Structs.DealRequest calldata deal) external {
        dealRequests.push(deal);
    }

    function setDealRequestIdx(bytes32 id, uint256 index) external authorize {
        dealRequestIdx[id] = Structs.RequestIdx(index, true);
    }

    function setPieceRequest(bytes calldata pieceCid, bytes32 requestId) external authorize {
        pieceRequests[pieceCid] = Structs.RequestId(requestId, true);
    }

    function setPieceStatus(bytes calldata pieceCid, Status status) external authorize {
        pieceStatus[pieceCid] = status;
    }

    function setPieceProvider(bytes calldata cid, Structs.ProviderSet calldata pieceProvider) external authorize {
        pieceProviders[cid] = pieceProvider;
    }

    function setPieceDeal(bytes calldata cid, uint64 dealId) external authorize {
        pieceDeals[cid] = dealId;
    }

    function setFilDeposit(address user, uint256 amount) external authorize {
        filDeposits[user] = amount;
    }

    function getActiveCids() public view returns (bytes[] memory) {
        return activeCids;
    } 

    function getExtraParams(
        bytes32 proposalId
    ) public view returns (bytes memory extra_params) {
        Structs.DealRequest memory deal = getDealRequest(proposalId);
        return Utils.serializeExtraParamsV1(deal.extra_params);
    }

    // Returns a CBOR-encoded DealProposal.
    function getDealProposal(
        bytes32 proposalId
    ) public view returns (bytes memory) {
        Structs.DealRequest memory deal = getDealRequest(proposalId);

        MarketTypes.DealProposal memory ret;
        ret.piece_cid = CommonTypes.Cid(deal.piece_cid);
        ret.piece_size = deal.piece_size;
        ret.verified_deal = deal.verified_deal;
        ret.client = Utils.getDelegatedAddress(address(this));
        // Set a dummy provider. The provider that picks up this deal will need to set its own address.
        ret.provider = FilAddresses.fromActorID(0);
        ret.label = CommonTypes.DealLabel(bytes(deal.label), true);
        ret.start_epoch = CommonTypes.ChainEpoch.wrap(deal.start_epoch);
        ret.end_epoch = CommonTypes.ChainEpoch.wrap(deal.end_epoch);
        ret.storage_price_per_epoch = Utils.uintToBigInt(
            deal.storage_price_per_epoch
        );
        ret.provider_collateral = Utils.uintToBigInt(deal.provider_collateral);
        ret.client_collateral = Utils.uintToBigInt(deal.client_collateral);

        return MarketCBOR.serializeDealProposal(ret);
    }
}
