//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpiderToken is ERC20, Ownable{

    constructor() ERC20("spider", "sT") Ownable(msg.sender){
        // The initial supply will be managed by the owner minting tokens as needed,
        // rather than minting a fixed supply at deployment.
    }

    function mint(address _to, uint256 _value) external onlyOwner {
        _mint(_to, _value);
    }


}