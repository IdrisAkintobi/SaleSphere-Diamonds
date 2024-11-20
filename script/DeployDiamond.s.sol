// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { IDiamondCut } from "../src/interfaces/IDiamondCut.sol";
import { DiamondCutFacet } from "../src/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../src/facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "../src/facets/OwnershipFacet.sol";
import { Diamond } from "../src/Diamond.sol";
import { DiamondUtils } from "./helpers/DiamondUtils.sol";
import { InventoryManagementFacet } from "../src/facets/InventoryManagementFacet.sol";
import { SalesFacet } from "../src/facets/SalesFacet.sol";
import { StaffManagementFacet } from "../src/facets/StaffManagementFacet.sol";
import { Script, console } from "../lib/forge-std/src/Script.sol";

contract DiamondDeployerScript is DiamondUtils {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    InventoryManagementFacet inventoryF;
    SalesFacet salesF;
    StaffManagementFacet staffMngtF;

    address owner;
    uint16 maxAdmins;
    uint24 maxQuantity;
    uint16 productLowMargin;

    function setUp() public {
        owner = vm.envAddress("INITIAL_OWNER");
        maxAdmins = vm.envUint("MAX_ADMIN");
        maxQuantity = vm.envUint("MAX_QUANTITY");
        productLowMargin = vm.envUint("PRODUCT_MARGIN");
    }

    function run() public {
        // Start the broadcast
        vm.startBroadcast();
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(dCutFacet), maxAdmins, maxQuantity, productLowMargin);
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        inventoryF = new InventoryManagementFacet();
        salesF = new SalesFacet();
        staffMngtF = new StaffManagementFacet();

        //upgrade diamond with facets
        //build cut struct
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](5);

        cut[0] = (
            IDiamondCut.FacetCut({
                facetAddress: address(dLoupe),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            IDiamondCut.FacetCut({
                facetAddress: address(ownerF),
                action: IDiamondCut.FacetCutAction.Add,
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

        // Stop broadcasting
        vm.stopBroadcast();

        console.log("Diamond deployed to:", address(diamond));
    }
}
