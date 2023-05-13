pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MintableNFT is ERC721 {
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function safeMint(uint256 tokenID) public {
        _safeMint(msg.sender, tokenID);
    }
}
