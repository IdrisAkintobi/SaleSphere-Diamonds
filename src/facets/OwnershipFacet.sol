// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IERC173 } from "../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.transferOwnership(_newOwner);
    }

    function acceptOwnership() external {
        LibDiamond.enforceIsProposedOwner();
        LibDiamond.acceptOwnership();
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}
