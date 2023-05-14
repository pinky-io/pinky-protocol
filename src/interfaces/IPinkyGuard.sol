// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IPinkyGuard is IERC165 {
    function addRent(address nftContract, uint256 _NftTokenId) external;
    function deleteRent(address nftContract, uint256 _NftTokenId) external;
}
