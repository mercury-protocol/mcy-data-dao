// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {CommonTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import {BigIntCBOR} from "@zondax/filecoin-solidity/contracts/v0.8/cbor/BigIntCbor.sol";
import {CBORDecoder} from "@zondax/filecoin-solidity/contracts/v0.8/utils/CborDecode.sol";
import {AccountTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/AccountTypes.sol";
import {MarketTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";
import {MarketCBOR} from "@zondax/filecoin-solidity/contracts/v0.8/cbor/MarketCbor.sol";
import "@zondax/solidity-bignumber/src/BigNumbers.sol";
import "solidity-cborutils/contracts/CBOR.sol";
import "./Structs.sol";
import "./Constants.sol";
import "./Errors.sol";

library Utils {
    using CBOR for CBOR.CBORBuffer;
    using CBORDecoder for bytes;
    using BigIntCBOR for CommonTypes.BigInt;
    using BigIntCBOR for bytes;

    // TODO: Below 2 funcs need to go to filecoin.sol
    function uintToBigInt(
        uint256 value
    ) public view returns (CommonTypes.BigInt memory) {
        BigNumber memory bigNumVal = BigNumbers.init(value, false);
        CommonTypes.BigInt memory bigIntVal = CommonTypes.BigInt(
            bigNumVal.val,
            bigNumVal.neg
        );
        return bigIntVal;
    }

    function bigIntToUint(
        CommonTypes.BigInt memory bigInt
    ) public view returns (uint256) {
        BigNumber memory bigNumUint = BigNumbers.init(bigInt.val, bigInt.neg);
        uint256 bigNumExtractedUint = uint256(bytes32(bigNumUint.val));
        return bigNumExtractedUint;
    }

    // TODO fix in filecoin-solidity. They're using the wrong hex value.
    function getDelegatedAddress(
        address addr
    ) public pure returns (CommonTypes.FilAddress memory) {
        return CommonTypes.FilAddress(abi.encodePacked(hex"040a", addr));
    }

    function serializeExtraParamsV1(
        Structs.ExtraParamsV1 memory params
    ) public pure returns (bytes memory) {
        CBOR.CBORBuffer memory buf = CBOR.create(64);
        buf.startFixedArray(4);
        buf.writeString(params.location_ref);
        buf.writeUInt64(params.car_size);
        buf.writeBool(params.skip_ipni_announce);
        buf.writeBool(params.remove_unsealed_copy);
        return buf.data();
    }
}
