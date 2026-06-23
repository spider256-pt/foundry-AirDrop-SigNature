//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {AirDrop} from "../src/AirDrop.sol";
import {SpiderToken} from "../src/SpiderToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";



contract DeployMerkleAirDrop is Script {

    bytes32 private s_merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private s_amountToTransfer = 4 * 25 * 1e18;


    function run() external returns(AirDrop, SpiderToken){
        return deployMerkleAirDrop();
    }

    function deployMerkleAirDrop() public returns(AirDrop, SpiderToken){
        vm.startBroadcast();

        SpiderToken token = new SpiderToken();
        AirDrop airdrop = new AirDrop(s_merkleRoot, token);

        token.mint(token.owner(), s_amountToTransfer);
        token.transfer(address(airdrop), s_amountToTransfer);

        vm.stopBroadcast();
        return (airdrop, token);
    }

   
}