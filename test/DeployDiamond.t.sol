// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

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

    address owner;
    uint16 maxAdmins = 10;
    uint24 maxQuantity = 1e6;
    uint16 productLowMargin = 24;

    function setUp() public {
        merkleRoot = getMerkleTreeRoot();

        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet), maxAdmins, maxQuantity, productLowMargin);
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        inventoryF = new InventoryManagementFacet();
        salesF = new SalesFacet();
        staffMngtF = new StaffManagementFacet();

        //upgrade diamond with facets
        //build cut struct
        FacetCut[] memory cut = new FacetCut[](4);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            IDiamondCut.FacetCut({
                facetAddress: address(inventoryF),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: generateSelectors("InventoryManagementFacet")
            })
        );

        cut[3] = (
            IDiamondCut.FacetCut({
                facetAddress: address(salesF),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: generateSelectors("SalesFacet")
            })
        );

        cut[4] = (
            IDiamondCut.FacetCut({
                facetAddress: address(staffMngtF),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: generateSelectors("StaffManagementFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");
    }

    function test_DeployDiamond() public view {
        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override { }
}
