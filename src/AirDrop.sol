//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    MerkleProof
} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AirDrop is EIP712 {
    using SafeERC20 for IERC20;

    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airDropToken;
    mapping(address claiment => bool) private s_hasClaimed;

    bytes32 private constant MESSAGE_TYPEHASH =
        0xaa726e564e52b64144617a6a46c42e8b763d4d224ca1a3e13c1491f8a4763a23;

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    event Claim(address indexed account, uint256 amount);

    error MerkleAirdrop__InvalidSignature();
    error MerkleAirdrop__InvalidProof();
    error UserClaimed__Already();

    constructor(
        bytes32 merkleRoot,
        IERC20 airdropToken
    ) EIP712("MerkleAirDrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airDropToken = airdropToken;
    }

    function getMessage(
        address account,
        uint256 amount
    ) public view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(MESSAGE_TYPEHASH, account, amount)
        );
        return _hashTypedDataV4(structHash);
    }

    function _isValidSignature(
        address expectedSigner,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        address actualSigner = ECDSA.recover(digest, v, r, s);

        return actualSigner != address(0) && actualSigner == expectedSigner;
    }

    /**
     * @dev This function allow user to get their air drops.
     * @param account The address of the user or EOA.
     * @param amount The amount of tokens the user or EOA wanted to claim.
     * @param merkleProof An array of hashes of the user for validation using the merkle Root.
     */
    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Inside the claim function:
        // Calculate the leaf Hash.
        // This implementation double-hashes the abi.encoded data.
        // Consistency between off-chain leaf generation and on-chain verification is paramount.

        if (s_hasClaimed[account]) {
            revert UserClaimed__Already();
        }
        bytes32 digest = getMessage(account, amount);

        if (!_isValidSignature(account, digest, v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(account, amount)))
        );
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasClaimed[account] = true;

        emit Claim(account, amount);

        i_airDropToken.safeTransfer(account, amount);
    }

    function getmerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirDropToken() external view returns (IERC20) {
        return i_airDropToken;
    }
}
