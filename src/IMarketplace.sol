// SPDX-License-Identifier: UNLICENSED

interface IMarketplace {
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

    function lend(address collectionAddress, uint256 tokenID, uint256 duration, uint256 pricePerDay) external;
    function rent(address collectionAddress, uint256 tokenID) external payable;
    function endRent(address collectionAddress, uint256 tokenID) external;
    function deleteOffer(address collectionAddress, uint256 tokenID) external;
}
