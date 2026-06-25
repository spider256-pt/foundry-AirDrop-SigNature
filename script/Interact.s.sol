//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {AirDrop} from "../src/AirDrop.sol";

contract ClaimAirdrop is Script {
    address CLAIMING_ADRESS = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    uint256 CLAIMING_AMOUNT = 25 * 1e18;

    bytes32 PROOF_ONE =
        0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 PROOF_TWO =
        0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;

    bytes32[] private proof = [PROOF_ONE, PROOF_TWO];

    bytes private SIGNATURE =
        hex"7c7200104445d818bb058947ca4d0a740925117c2762842c9bd5742b44100c355d18cd02ee1ffd22783aee0c86bb7ebb8b86c1f38b63bd01b820e4688e7772ed1c";

    error Claim__Invalid__SignatureLength();

    /**
    @notice Splits 65-byte concatenated signature into (v,r,s)
    @param sig A concatenated signature as bytes
    @return v The recovery Identifier (1 byte)
    @return r The r value of the signature (32 byte)
    @return s The s value of the signature (32 byte)
    */
    function splitSignature(
        bytes memory sig
    ) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert Claim__Invalid__SignatureLength();
        }

        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }
    }

    function claimAirdrop(address airdropContractAddress) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        AirDrop(airdropContractAddress).claim(
            CLAIMING_ADRESS,
            CLAIMING_AMOUNT,
            proof,
            v,
            r,
            s
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "AirDrop",
            block.chainid
        );
        claimAirdrop(mostRecentlyDeployed);
    }
}
