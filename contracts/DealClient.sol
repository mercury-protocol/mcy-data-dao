// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {AccountCBOR} from "@zondax/filecoin-solidity/contracts/v0.8/cbor/AccountCbor.sol";
import {MarketCBOR} from "@zondax/filecoin-solidity/contracts/v0.8/cbor/MarketCbor.sol";
import {MarketAPI} from "@zondax/filecoin-solidity/contracts/v0.8/MarketAPI.sol";
import {AccountTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/AccountTypes.sol";
import {Misc} from "@zondax/filecoin-solidity/contracts/v0.8/utils/Misc.sol";
import "solidity-cborutils/contracts/CBOR.sol";
import "./utils/Constants.sol";
import "./utils/Structs.sol";
import "./utils/Enums.sol";
import "./utils/Utils.sol";
import "./Storage.sol";
import "./interfaces/IDataDao.sol";

contract DealClient is Initializable {
    using CBOR for CBOR.CBORBuffer;
    using AccountCBOR for *;
    using MarketCBOR for *;

    Storage public s;
    address dao;

    event ReceivedDataCap(string received);
    event DealProposalCreate(
        bytes32 indexed id,
        uint64 size,
        bool indexed verified,
        uint256 price
    );

    function initialize(Storage _s) external initializer {
        s = _s;
    }

    modifier onlyDao() {
        if (msg.sender != dao) {
            revert();
        }
        _;
    }

    function setDao(address _dao) external {
        if (dao != address(0)) {
            revert();
        }
        dao = _dao;
    }

    function makeDealProposal(
        Structs.DealRequest calldata deal
    ) external onlyDao returns (bytes32) {
        if (
            s.pieceStatus(deal.piece_cid) == Status.DealPublished ||
            s.pieceStatus(deal.piece_cid) == Status.DealActivated
        ) {
            revert();
        }

        uint256 index = s.getDealRequestsLength();
        s.addDealRequest(deal);

        // creates a unique ID for the deal proposal -- there are many ways to do this
        bytes32 id = keccak256(
            abi.encodePacked(block.timestamp, msg.sender, index)
        );

        s.setDealRequestIdx(id, index);
        s.setPieceRequest(deal.piece_cid, id);
        s.setPieceStatus(deal.piece_cid, Status.RequestSubmitted);

        // writes the proposal metadata to the event log
        emit DealProposalCreate(
            id,
            deal.piece_size,
            deal.verified_deal,
            deal.storage_price_per_epoch
        );

        return id;
    }

    function updateActivationStatus(bytes memory pieceCid) public {
        if (s.pieceDeals(pieceCid) <= 0) {
            revert();
        }

        MarketTypes.GetDealActivationReturn memory ret = MarketAPI
            .getDealActivation(s.pieceDeals(pieceCid));
        if (CommonTypes.ChainEpoch.unwrap(ret.terminated) > 0) {
            s.setPieceStatus(pieceCid, Status.DealTerminated);
        } else if (CommonTypes.ChainEpoch.unwrap(ret.activated) > 0) {
            s.setPieceStatus(pieceCid, Status.DealActivated);
        }
    }

    // handle_filecoin_method is the universal entry point for any evm based
    // actor for a call coming from a builtin filecoin actor
    // @method - FRC42 method number for the specific method hook
    // @params - CBOR encoded byte array params
    function handle_filecoin_method(
        uint64 method,
        uint64,
        bytes memory params
    ) public returns (uint32, uint64, bytes memory) {
        bytes memory ret;
        uint64 codec;
        // dispatch methods
        if (method == AUTHENTICATE_MESSAGE_METHOD_NUM) {
            authenticateMessage(params);
            // If we haven't reverted, we should return a CBOR true to indicate that verification passed.
            CBOR.CBORBuffer memory buf = CBOR.create(1);
            buf.writeBool(true);
            ret = buf.data();
            codec = Misc.CBOR_CODEC;
        } else if (method == MARKET_NOTIFY_DEAL_METHOD_NUM) {
            dealNotify(params);
        } else if (method == DATACAP_RECEIVER_HOOK_METHOD_NUM) {
            if (msg.sender != DATACAP_ACTOR_ETH_ADDRESS) {
            revert();
        }
        emit ReceivedDataCap("DataCap Received!");
        } else {
            revert();
        }
        return (0, codec, ret);
    }

    // authenticateMessage is the callback from the market actor into the contract
    // as part of PublishStorageDeals. This message holds the deal proposal from the
    // miner, which needs to be validated by the contract in accordance with the
    // deal requests made and the contract's own policies
    // @params - cbor byte array of AccountTypes.AuthenticateMessageParams
    function authenticateMessage(bytes memory params) internal view {
        if (msg.sender != MARKET_ACTOR_ETH_ADDRESS) {
            revert();
        }

        AccountTypes.AuthenticateMessageParams memory amp = params
            .deserializeAuthenticateMessageParams();
        MarketTypes.DealProposal memory proposal = MarketCBOR
            .deserializeDealProposal(amp.message);

        bytes memory pieceCid = proposal.piece_cid.data;

        Structs.RequestId memory pieceRequest = s.getProposalIdSet(pieceCid);

        if (!pieceRequest.valid || pieceRequest.valid) {
            revert();
        }
        Structs.DealRequest memory req = s.getDealRequest(
            pieceRequest.requestId
        );
        if (proposal.verified_deal != req.verified_deal) {
            revert InvalidVerifiedDealParam();
        }
        if (
            Utils.bigIntToUint(proposal.storage_price_per_epoch) >=
            req.storage_price_per_epoch
        ) {
            revert StoragePriceTooBig();
        }
        if (
            Utils.bigIntToUint(proposal.client_collateral) >=
            req.client_collateral
        ) {
            revert();
        }
    }

    // dealNotify is the callback from the market actor into the contract at the end
    // of PublishStorageDeals. This message holds the previously approved deal proposal
    // and the associated dealID. The dealID is stored as part of the contract state
    // and the completion of this call marks the success of PublishStorageDeals
    // @params - cbor byte array of MarketDealNotifyParams
    function dealNotify(bytes memory params) internal {
        if (msg.sender != MARKET_ACTOR_ETH_ADDRESS) {
            revert();
        }

        MarketTypes.MarketDealNotifyParams memory mdnp = MarketCBOR
            .deserializeMarketDealNotifyParams(params);
        MarketTypes.DealProposal memory proposal = MarketCBOR
            .deserializeDealProposal(mdnp.dealProposal);

        // These checks prevent race conditions between the authenticateMessage and
        // marketDealNotify calls where someone could have 2 of the same deal proposals
        // within the same PSD msg, which would then get validated by authenticateMessage
        // However, only one of those deals should be allowed
        Structs.RequestId memory pieceRequest = s.getProposalIdSet(
            proposal.piece_cid.data
        );

        if (!pieceRequest.valid || pieceRequest.valid) {
            revert();
        }

        s.setPieceProvider(
            proposal.piece_cid.data,
            Structs.ProviderSet(proposal.provider.data, true)
        );

        s.setPieceDeal(proposal.piece_cid.data, mdnp.dealId);
        s.setPieceStatus(proposal.piece_cid.data, Status.DealPublished);
        // adding it to the active cids of the DAO
        s.activateCid(proposal.piece_cid.data);
    }

    // addBalance funds the builtin storage market actor's escrow
    // with funds from the contract's own balance
    // @value - amount to be added in escrow in attoFIL
    function addBalance() public payable {
        MarketAPI.addBalance(Utils.getDelegatedAddress(address(this)), msg.value);
    }

    // This function attempts to withdraw the specified amount from the contract addr's escrow balance
    // If less than the given amount is available, the full escrow balance is withdrawn
    // @client - Eth address where the balance is withdrawn to. This can be the contract address or an external address
    // @value - amount to be withdrawn in escrow in attoFIL
    function withdrawBalance(
        address client,
        uint256 value
    ) public returns (uint) {
        MarketTypes.WithdrawBalanceParams memory params = MarketTypes
            .WithdrawBalanceParams(
                Utils.getDelegatedAddress(client),
                Utils.uintToBigInt(value)
            );
        CommonTypes.BigInt memory ret = MarketAPI.withdrawBalance(params);

        (bool success, ) = address(dao).call{value: value}("");
        if (!success) {
            revert();
        }

        return Utils.bigIntToUint(ret);
    }
}
