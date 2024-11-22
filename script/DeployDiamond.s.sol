// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

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
import { DiamondInit } from "../src/upgradeInitializers/DiamondInit.sol";

contract DiamondDeployerScript is DiamondUtils {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    InventoryManagementFacet inventoryF;
    SalesFacet salesF;
    StaffManagementFacet staffMngtF;

    address storeOwner;
    uint16 maxAdmins;
    uint24 maxQuantity;
    uint16 productLowMargin;

    function setUp() public {
        storeOwner = vm.envAddress("STORE_OWNER");
        maxAdmins = uint16(vm.envUint("MAX_ADMIN"));
        maxQuantity = uint24(vm.envUint("MAX_QUANTITY"));
    }

    function run() public {
        // Start the broadcast
        vm.startBroadcast();
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(storeOwner, address(dCutFacet), maxAdmins, maxQuantity);
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        staffMngtF = new StaffManagementFacet();
        inventoryF = new InventoryManagementFacet();
        salesF = new SalesFacet();

        // Deploy DiamondInit
        DiamondInit diamondInit = new DiamondInit();
        bytes memory diamondInitCalldata = abi.encodeWithSignature("init()");

        //build cut struct
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](5);
        cut[0] = _createFacetCut(address(dLoupe), "DiamondLoupeFacet");
        cut[1] = _createFacetCut(address(ownerF), "OwnershipFacet");
        cut[2] = _createFacetCut(address(staffMngtF), "StaffManagementFacet");
        cut[3] = _createFacetCut(address(inventoryF), "InventoryManagementFacet");
        cut[4] = _createFacetCut(address(salesF), "SalesFacet");

        //upgrade diamond with facets
        IDiamondCut(address(diamond)).diamondCut(cut, address(diamondInit), diamondInitCalldata);

        // Stop broadcasting
        vm.stopBroadcast();

        console.log("Diamond deployed to:", address(diamond));
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
}
