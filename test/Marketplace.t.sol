// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// import "./external/SafeDeployer.sol"; // conflict with erc165.sol between safe-contracts and openzeppelin
import "./external/MintableNFT.sol";
import "../src/IMarketplace.sol";
import "../src/Marketplace.sol";

contract MarketplaceTest is Test {
    MintableNFT nft;
    Marketplace marketplace;

    function setUp() public {
        nft = new MintableNFT("Test NFT", "JH");
        marketplace = new Marketplace();

        hoax(makeAddr("user1"));
        nft.safeMint(1);
        hoax(makeAddr("user2"));
        nft.safeMint(2);
        hoax(makeAddr("user3"));
        nft.safeMint(3);
    }

    // error 2333 is too strong for me :(
    // function testDeploySafe() public {
    //     SafeDeployer deployer = new SafeDeployer();
    //     address[] memory owners = new Address[](1);
    //     address safe = deployer.deploySafe(_owners, 1);
    // }

    function testLend() public {
        uint256 duration = 2; // days
        uint256 pricePerDay = 123 wei;
        uint256 tokenID = 1;
        address lender = makeAddr("user1");

        // Approve the token
        hoax(lender);
        nft.approve(address(marketplace), tokenID);

        // List the token on the marketplace
        hoax(lender);
        marketplace.lend(address(nft), tokenID, duration, pricePerDay);

        // retrieve data
        Marketplace.LendData memory lendData = marketplace.getLending(address(nft), tokenID);

        assertEq(lendData.owner, lender, "lendData.owner should be the owner of the NFT");
        assertEq(lendData.collectionAddress, address(nft), "lendData.collectionAddress should be the NFT address");
        assertEq(lendData.tokenID, tokenID, "lendData.tokenID should be the NFT ID");
        assertEq(lendData.duration, duration, "lendData.duration should be the provided duration");
        assertEq(lendData.pricePerDay, pricePerDay, "lendData.pricePerDay should be the provided pricePerDay");
    }

    function testRent() public {
        uint256 duration = 10;
        uint256 pricePerDay = 1 ether;
        uint256 tokenID = 2;
        address lender = makeAddr("user2");
        address borrower = makeAddr("user3");

        // register a lending offer
        hoax(lender);
        nft.approve(address(marketplace), tokenID);
        hoax(lender);
        marketplace.lend(address(nft), tokenID, duration, pricePerDay);

        // set marketplace as Approval
        hoax(borrower);
        nft.setApprovalForAll(address(marketplace), true);

        // rent the NFT
        hoax(borrower);
        marketplace.rent{value: pricePerDay * duration}(address(nft), tokenID);

        // retrieve data
        Marketplace.RentData memory rentData = marketplace.getRenting(address(nft), tokenID);

        assertEq(rentData.borrower, borrower, "rentData.borrower should be the borrower address");
        assertEq(rentData.startingDate, block.timestamp, "rentData.startingDate should be the current block timestamp");
        assertEq(nft.ownerOf(tokenID), borrower, "NFT should be transferred to the borrower");
    }

    function testEndRent() public {
        uint256 duration = 21;
        uint256 pricePerDay = 42 ether;
        uint256 tokenID = 3;
        address lender = makeAddr("user3");
        address borrower = makeAddr("user1");

        // register a lending offer
        hoax(lender);
        nft.approve(address(marketplace), tokenID);
        hoax(lender);
        marketplace.lend(address(nft), tokenID, duration, pricePerDay);

        // set marketplace as Approval
        hoax(borrower);
        nft.setApprovalForAll(address(marketplace), true);

        // rent the NFT
        hoax(borrower);
        marketplace.rent{value: pricePerDay * duration}(address(nft), tokenID);

        // fast forward until the end of the rent
        vm.warp(block.timestamp + duration * 1 days);

        // claim back the NFT
        hoax(lender);
        marketplace.endRent(address(nft), tokenID);

        assertEq(nft.ownerOf(tokenID), lender, "NFT should be transferred back to the lender");
        assertEq(marketplace.getLending(address(nft), tokenID).owner, address(0), "Lending offer should be deleted");
        assertEq(marketplace.getRenting(address(nft), tokenID).borrower, address(0), "Renting offer should be deleted");
    }

    function testDeleteOffer() public {
        uint256 duration = 5;
        uint256 pricePerDay = 55 wei;
        uint256 tokenID = 1;
        address lender = makeAddr("user1");

        // register a lending offer
        hoax(lender);
        nft.approve(address(marketplace), tokenID);
        hoax(lender);
        marketplace.lend(address(nft), tokenID, duration, pricePerDay);

        // delete the offer
        hoax(lender);
        marketplace.deleteOffer(address(nft), tokenID);

        assertEq(nft.ownerOf(tokenID), lender, "NFT should be transferred back to the lender");
        assertEq(marketplace.getLending(address(nft), tokenID).owner, address(0), "Lending offer should be deleted");
    }
}
