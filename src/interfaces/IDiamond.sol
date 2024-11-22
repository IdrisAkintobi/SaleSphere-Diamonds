// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDiamond {
    //immutable functions
    function getStoreDetails() external view returns (string memory);
    function updateStoreDetailsHash(string calldata newHash) external;
}
