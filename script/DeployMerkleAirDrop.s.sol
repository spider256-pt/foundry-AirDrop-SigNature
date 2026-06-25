//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {AirDrop} from "../src/AirDrop.sol";
import {SpiderToken} from "../src/SpiderToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirDrop is Script {
    bytes32 private s_merkleRoot =
        0xbf1a57dfd8160aa9ade95c6c0358f7fdb510bbc7bb5218ed40989cb83d4ee720;
    uint256 private s_amountToTransfer = 4 * 25 * 1e18;

    function run() external returns (AirDrop, SpiderToken) {
        return deployMerkleAirDrop();
    }

    function deployMerkleAirDrop() public returns (AirDrop, SpiderToken) {
        vm.startBroadcast();

        SpiderToken token = new SpiderToken();
        AirDrop airdrop = new AirDrop(s_merkleRoot, token);

        token.mint(token.owner(), s_amountToTransfer);
        token.transfer(address(airdrop), s_amountToTransfer);

        vm.stopBroadcast();
        return (airdrop, token);
    }
}
