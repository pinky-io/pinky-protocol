// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IStorageAccessible {
    function getStorageAt(uint256 offset, uint256 length) external view returns (bytes memory);
}
