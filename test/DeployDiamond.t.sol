// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IDiamondCut } from "../src/interfaces/IDiamondCut.sol";
import { DiamondCutFacet } from "../src/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../src/facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "../src/facets/OwnershipFacet.sol";
import { Diamond } from "../src/Diamond.sol";
import { DiamondUtils } from "../script/helpers/DiamondUtils.sol";
import { InventoryManagementFacet } from "../src/facets/InventoryManagementFacet.sol";
import { SalesFacet } from "../src/facets/SalesFacet.sol";
import { StaffManagementFacet } from "../src/facets/StaffManagementFacet.sol";
import { Test, console } from "../lib/forge-std/src/Test.sol";

contract DiamondDeployer is DiamondUtils, IDiamondCut, Test {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    InventoryManagementFacet inventoryF;
    SalesFacet salesF;
    StaffManagementFacet staffMngtF;

    address storeOwner = address(this);
    uint16 constant maxAdmins = 10;
    uint24 constant maxQuantity = 1e6;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(storeOwner, address(dCutFacet), maxAdmins, maxQuantity);
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        inventoryF = new InventoryManagementFacet();
        salesF = new SalesFacet();
        staffMngtF = new StaffManagementFacet();

        //upgrade diamond with facets
        //build cut struct
        FacetCut[] memory cut = new FacetCut[](5);
        cut[0] = _createFacetCut(address(dLoupe), "DiamondLoupeFacet");
        cut[1] = _createFacetCut(address(ownerF), "OwnershipFacet");
        cut[2] = _createFacetCut(address(staffMngtF), "StaffManagementFacet");
        cut[3] = _createFacetCut(address(inventoryF), "InventoryManagementFacet");
        cut[4] = _createFacetCut(address(salesF), "SalesFacet");

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");
    }

    function _createFacetCut(address _facetAddress, string memory _facetName)
        private
        returns (IDiamondCut.FacetCut memory)
    {
        return IDiamondCut.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors(_facetName)
        });
    }

    function test_DeployDiamond() public view {
        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override { }
}
