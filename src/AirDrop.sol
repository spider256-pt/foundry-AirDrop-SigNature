//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AirDrop {

    using SafeERC20 for IERC20;
    
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airDropToken;
    mapping(address claiment => bool) private s_hasClaimed;

    event Claim(address indexed account, uint256 amount);


    error MerkleAirdrop__InvalidProof();
    error UserClaimed__Already();


    constructor(bytes32 merkleRoot, IERC20 airdropToken){
        i_merkleRoot = merkleRoot;
        i_airDropToken = airdropToken;
    }   

    /**
     * @dev This function allow user to get their air drops.
     * @param account The address of the user or EOA.
     * @param amount The amount of tokens the user or EOA wanted to claim.
     * @param merkleProof An array of hashes of the user for validation using the merkle Root.
     */
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        // Inside the claim function:
        // Calculate the leaf Hash.
        // This implementation double-hashes the abi.encoded data.
        // Consistency between off-chain leaf generation and on-chain verification is paramount.

        if (s_hasClaimed[account]){
            revert UserClaimed__Already();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if(!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)){
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasClaimed[account] = true;

        emit Claim(account, amount);

        i_airDropToken.safeTransfer(account, amount);
    }

    function getmerkleRoot() external view returns(bytes32){
        return i_merkleRoot;
    }

    function getAirDropToken() external view returns(IERC20){
        return i_airDropToken;
    }
    
}