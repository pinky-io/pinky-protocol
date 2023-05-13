// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// NFT Lending protocol leveraging account abstraction features to allow:
// - true ownership & asset securing by smart contract wallet
// - no collateral & no escrow
// - peer to peer matching for the offers
contract Marketplace {
    event Lend(address collectionAddress, uint256 tokenID, address owner, uint256 duration, uint256 pricePerDay);
    event Rent(address collectionAddress, uint256 tokenID, address borrower, uint256 startingDate);
    event DeleteLend(address collectionAddress, uint256 tokenID);
    event DeleteRent(address collectionAddress, uint256 tokenID);

    struct LendData {
        address owner;
        address collectionAddress;
        uint256 tokenID;
        uint256 duration; // in day
        uint256 pricePerDay; // in wei
    }

    struct RentData {
        address borrower;
        uint256 startingDate; // timestamp
    }

    // Lendings and Rentings are referenced by a common ID, which is
    // a hash of the NFT collection address & the token ID.
    // This way, only one lending offer can exist per token.
    mapping(bytes32 => LendData) private lendings;
    mapping(bytes32 => RentData) private rentings;

    function getLending(address collectionAddress, uint256 tokenID) public view returns (LendData memory) {
        bytes32 lendingID = keccak256(abi.encodePacked(collectionAddress, tokenID));
        return lendings[lendingID];
    }

    function getRenting(address collectionAddress, uint256 tokenID) public view returns (RentData memory) {
        bytes32 lendingID = keccak256(abi.encodePacked(collectionAddress, tokenID));
        return rentings[lendingID];
    }

    // List an NFT to the marketplace for a given duration
    function lend(address collectionAddress, uint256 tokenID, uint256 duration, uint256 pricePerDay) external {
        bytes32 lendingID = keccak256(abi.encodePacked(collectionAddress, tokenID));

        require(IERC721(collectionAddress).ownerOf(tokenID) == msg.sender, "msg.sender is not owner of the token");
        require(rentings[lendingID].borrower == address(0), "token is already rented");
        require(
            IERC721(collectionAddress).getApproved(tokenID) == address(this),
            // NB: if marketplace is operator, a Lend offer could still be valid after a transfer of the token
            // || IERC721(collectionAddress).isApprovedForAll(msg.sender, address(this)),
            "Must approve marketplace to transfer the token beforehand"
        );

        LendData memory lendData = LendData(msg.sender, collectionAddress, tokenID, duration, pricePerDay);
        lendings[lendingID] = lendData;

        emit Lend(collectionAddress, tokenID, msg.sender, duration, pricePerDay);
    }

    // Borrow an NFT that has been listed
    function rent(address collectionAddress, uint256 tokenID) external payable {
        address owner = IERC721(collectionAddress).ownerOf(tokenID);
        bytes32 lendingID = keccak256(abi.encodePacked(collectionAddress, tokenID));

        // check if lending offer is valid
        LendData memory lendData = lendings[lendingID];
        require(lendData.owner != address(0), "Non existant lending offer");
        require(lendData.owner == owner, "Unvalid lending offer");

        // check if borrower has set marketplace as operator (marketplace can't set it by itself)
        // NB: it can't work with 'approve()' because this function can only be call by owner / operator
        require(
            IERC721(collectionAddress).isApprovedForAll(msg.sender, address(this)),
            "borrower must set marketplace as operator"
        );

        // todo: check if borrower is a Safe with the right guard

        // check if correct amount of eth has been sent
        uint256 totalPrice = lendData.pricePerDay * lendData.duration;
        require(msg.value == totalPrice, "unvalid eth amount sent");

        // register the rent & send the nft
        // NB: safeTransferFrom() checks if recipient is a ERC721Receiver, but it adds a reentrancy vulnerability
        RentData memory rentData = RentData(msg.sender, block.timestamp);
        IERC721(collectionAddress).safeTransferFrom(owner, msg.sender, tokenID);
        (bool sent, bytes memory data) = lendData.owner.call{value: msg.value}("");
        require(sent, "Failed to send Ether to NFT owner");
        rentings[lendingID] = rentData;

        emit Rent(collectionAddress, tokenID, msg.sender, block.timestamp);
    }

    function _deleteOffer(bytes32 lendingID) internal {
        delete lendings[lendingID];
        delete rentings[lendingID];
    }

    // Claim back the borrowed NFT and delete Rent & Lend data
    // Can be called by owner or borrower
    function endRent(address collectionAddress, uint256 tokenID) external {
        bytes32 lendingID = keccak256(abi.encodePacked(collectionAddress, tokenID));
        LendData memory lendData = lendings[lendingID];
        RentData memory rentData = rentings[lendingID];

        require(msg.sender == lendData.owner || msg.sender == rentData.borrower, "must be called by lender or borrower");
        require(block.timestamp >= rentData.startingDate + lendData.duration * 1 days, "Renting is not over yet");

        _deleteOffer(lendingID);
        emit DeleteLend(collectionAddress, tokenID);
        emit DeleteRent(collectionAddress, tokenID);
        IERC721(collectionAddress).safeTransferFrom(rentData.borrower, lendData.owner, tokenID);
    }

    // delete an existing offer
    function deleteOffer(address collectionAddress, uint256 tokenID) external {
        bytes32 lendingID = keccak256(abi.encodePacked(collectionAddress, tokenID));
        LendData memory lendData = lendings[lendingID];
        RentData memory rentData = rentings[lendingID];

        require(msg.sender == lendData.owner, "must be called by lender");
        require(rentData.borrower == address(0), "Can't delete a lend offer if there is an ongoing rent");

        _deleteOffer(lendingID);
        emit DeleteLend(collectionAddress, tokenID);
    }
}
