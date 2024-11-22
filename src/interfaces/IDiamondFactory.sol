// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDiamondFactory {
    function deployDiamond(address _storeOwner, uint16 _maxAdmins, uint24 _maxQuantity)
        external
        returns (address diamondAddr, uint256 index);

    function getDiamondContract(uint256 index) external view returns (address);
}
