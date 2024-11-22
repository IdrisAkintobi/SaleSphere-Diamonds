// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IDiamondLoupe } from "../../src/interfaces/IDiamondLoupe.sol";
import { IERC173 } from "../../src/interfaces/IERC173.sol";
import { IInventoryManagement } from "../../src/interfaces/IInventoryManagement.sol";
import { ISales } from "../../src/interfaces/ISales.sol";
import { IStaffManagement } from "../../src/interfaces/IStaffManagement.sol";
import { console } from "../../lib/forge-std/src/Script.sol";

/**
 * @title Facet selectors generator for factory diamond
 * @notice It is used when deploying diamond via the factory to ensure the deployed facets have expected selectors
 */
library SelectorGenerator {
    error UnknownFacet();
    error SelectorDoesNotExistOnFacet(address facet, bytes4 selector);

    event SelectorError(address facet, bytes4 selector);

    function generateSelectors(address _facetAddr, string memory _facetName) internal view returns (bytes4[] memory) {
        // Mapping of facet names to their function selectors
        if (keccak256(abi.encodePacked(_facetName)) == keccak256(abi.encodePacked("DiamondLoupeFacet"))) {
            return generateDiamondLoupeFacetSelectors(_facetAddr);
        } else if (keccak256(abi.encodePacked(_facetName)) == keccak256(abi.encodePacked("OwnershipFacet"))) {
            return generateOwnershipFacetSelectors(_facetAddr);
        } else if (keccak256(abi.encodePacked(_facetName)) == keccak256(abi.encodePacked("StaffManagementFacet"))) {
            return generateStaffManagementFacetSelectors(_facetAddr);
        } else if (keccak256(abi.encodePacked(_facetName)) == keccak256(abi.encodePacked("InventoryManagementFacet"))) {
            return generateInventoryManagementFacetSelectors(_facetAddr);
        } else if (keccak256(abi.encodePacked(_facetName)) == keccak256(abi.encodePacked("SalesFacet"))) {
            return generateSalesFacetSelectors(_facetAddr);
        }

        // Fallback for unknown facet
        revert UnknownFacet();
    }

    function generateDiamondLoupeFacetSelectors(address addr) internal view returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = IDiamondLoupe.facets.selector;
        selectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        selectors[2] = IDiamondLoupe.facetAddresses.selector;
        selectors[3] = IDiamondLoupe.facetAddress.selector;

        // Check if all selectors exist on the contractAddress
        for (uint256 i = 0; i < selectors.length; i++) {
            bool success = _isSelectorImplemented(addr, selectors[i]);
            require(success, SelectorDoesNotExistOnFacet(addr, selectors[i]));
        }

        return selectors;
    }

    function generateOwnershipFacetSelectors(address addr) internal view returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = IERC173.owner.selector;
        selectors[1] = IERC173.transferOwnership.selector;
        selectors[2] = IERC173.acceptOwnership.selector;

        // Check if all selectors exist on the contractAddress
        for (uint256 i = 0; i < selectors.length; i++) {
            bool success = _isSelectorImplemented(addr, selectors[i]);
            require(success, SelectorDoesNotExistOnFacet(addr, selectors[i]));
        }

        return selectors;
    }

    function generateInventoryManagementFacetSelectors(address addr) internal view returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = IInventoryManagement.addNewProduct.selector;
        selectors[1] = IInventoryManagement.updateProductName.selector;
        selectors[2] = IInventoryManagement.updateProductPrice.selector;
        selectors[3] = IInventoryManagement.updateProductLowMargin.selector;
        selectors[4] = IInventoryManagement.getAllProducts.selector;
        selectors[5] = IInventoryManagement.deleteProduct.selector;

        // Check if all selectors exist on the contractAddress
        for (uint256 i = 0; i < selectors.length; i++) {
            bool success = _isSelectorImplemented(addr, selectors[i]);
            require(success, SelectorDoesNotExistOnFacet(addr, selectors[i]));
        }

        return selectors;
    }

    function generateSalesFacetSelectors(address addr) internal view returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = ISales.recordSale.selector;
        selectors[1] = ISales.getTotalSales.selector;

        // Check if all selectors exist on the contractAddress
        for (uint256 i = 0; i < selectors.length; i++) {
            bool success = _isSelectorImplemented(addr, selectors[i]);
            require(success, SelectorDoesNotExistOnFacet(addr, selectors[i]));
        }

        return selectors;
    }

    function generateStaffManagementFacetSelectors(address addr) internal view returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = IStaffManagement.updateAdminLimit.selector;
        selectors[1] = IStaffManagement.addStaff.selector;
        selectors[2] = IStaffManagement.setRole.selector;
        selectors[3] = IStaffManagement.updateStaffStatus.selector;
        selectors[4] = IStaffManagement.getStaffDetailsByAddress.selector;
        selectors[5] = IStaffManagement.getStaffDetailsByID.selector;
        selectors[6] = IStaffManagement.getAllStaff.selector;

        // Check if all selectors exist on the contractAddress
        for (uint256 i = 0; i < selectors.length; i++) {
            bool success = _isSelectorImplemented(addr, selectors[i]);
            require(success, SelectorDoesNotExistOnFacet(addr, selectors[i]));
        }

        return selectors;
    }

    function _isSelectorImplemented(address contractAddress, bytes4 selector) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(contractAddress)
        }
        if (size == 0) {
            return false; // No code at the address
        }

        bytes memory code = new bytes(size);
        assembly {
            extcodecopy(contractAddress, add(code, 0x20), 0, size)
        }

        // Look for the function selector in the bytecode
        for (uint256 i = 0; i < code.length - 4; i++) {
            if (
                code[i] == selector[0] && code[i + 1] == selector[1] && code[i + 2] == selector[2]
                    && code[i + 3] == selector[3]
            ) {
                return true; // Selector found
            }
        }
        return false; // Selector not found
    }
}
