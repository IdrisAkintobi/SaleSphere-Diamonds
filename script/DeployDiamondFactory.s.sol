// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script, console } from "../lib/forge-std/src/Script.sol";
import { DiamondFactory } from "../src/DiamondFactory.sol";
import { Script, console } from "../lib/forge-std/src/Script.sol";
import { IDiamondCut } from "../src/interfaces/IDiamondCut.sol";
import { DiamondCutFacet } from "../src/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../src/facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "../src/facets/OwnershipFacet.sol";
import { InventoryManagementFacet } from "../src/facets/InventoryManagementFacet.sol";
import { SalesFacet } from "../src/facets/SalesFacet.sol";
import { StaffManagementFacet } from "../src/facets/StaffManagementFacet.sol";

contract DeployDiamondFactory is Script {
    //contract types of facets to be deployed
    DiamondFactory diamondFactory;
    address dCutFacet;
    address dLoupe;
    address ownerF;
    address inventoryF;
    address salesF;
    address staffMngtF;

    function setUp() public { }

    function run() public returns (DiamondFactory) {
        // Start the broadcast
        vm.startBroadcast();

        //deploy facets
        dCutFacet = address(new DiamondCutFacet());
        dLoupe = address(new DiamondLoupeFacet());
        ownerF = address(new OwnershipFacet());
        staffMngtF = address(new StaffManagementFacet());
        inventoryF = address(new InventoryManagementFacet());
        salesF = address(new SalesFacet());

        // Deploy the Diamond Factory
        diamondFactory = new DiamondFactory(dCutFacet, dLoupe, ownerF, staffMngtF, inventoryF, salesF);

        // Stop broadcasting
        vm.stopBroadcast();

        // Log the deployed factory address
        console.log("Diamond Factory deployed to:", address(diamondFactory));

        return diamondFactory;
    }
}
