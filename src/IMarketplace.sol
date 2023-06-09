// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMarketplace {
    event Lend(
        address indexed collectionAddress,
        uint256 indexed tokenID,
        address indexed owner,
        uint256 duration,
        uint256 pricePerDay
    );
    event Rent(
        address indexed collectionAddress, uint256 indexed tokenID, address indexed borrower, uint256 startingDate
    );
    event DeleteLend(address indexed collectionAddress, uint256 indexed tokenID);
    event DeleteRent(address indexed collectionAddress, uint256 indexed tokenID);

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

    function lend(address collectionAddress, uint256 tokenID, uint256 duration, uint256 pricePerDay) external;
    function rent(address collectionAddress, uint256 tokenID) external payable;
    function endRent(address collectionAddress, uint256 tokenID) external;
    function deleteOffer(address collectionAddress, uint256 tokenID) external;
}
