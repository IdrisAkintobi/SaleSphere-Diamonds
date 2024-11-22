// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IDiamondCut } from "../src/interfaces/IDiamondCut.sol";
import { Diamond } from "../src/Diamond.sol";
import { SelectorGenerator } from "./utils/SelectorGenerator.sol";
import { IDiamondFactory } from "./interfaces/IDiamondFactory.sol";
import { DiamondInit } from "./upgradeInitializers/DiamondInit.sol";

contract DiamondFactory is IDiamondFactory {
    error InvalidIndex();

    event DiamondDeployed(address indexed DiamondAddress, uint256 indexed DiamondNumber);

    // Static addresses for facets (deployed once)
    address diamondCutF;
    address diamondLoupeF;
    address ownershipF;
    address staffManagementF;
    address inventoryManagementF;
    address salesF;

    address[] private diamondContracts;

    constructor(
        address diamondCutFacetAddr,
        address diamondLoupeFacetAddr,
        address ownershipFacetAddr,
        address staffManagementFacetAddr,
        address inventoryManagementFacetAddr,
        address salesFacetAddr
    ) {
        // Deploy facets only once during factory deployment
        diamondCutF = diamondCutFacetAddr;
        diamondLoupeF = diamondLoupeFacetAddr;
        ownershipF = ownershipFacetAddr;
        staffManagementF = staffManagementFacetAddr;
        inventoryManagementF = inventoryManagementFacetAddr;
        salesF = salesFacetAddr;
    }

    function deployDiamond(address _storeOwner, uint16 _maxAdmins, uint24 _maxQuantity)
        external
        returns (address diamondAddr, uint256 index)
    {
        // Use pre-deployed facet addresses
        Diamond diamond = new Diamond(_storeOwner, diamondCutF, _maxAdmins, _maxQuantity);

        // Deploy DiamondInit
        DiamondInit diamondInit = new DiamondInit();
        bytes memory diamondInitCalldata = abi.encodeWithSignature("init()");

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](5);
        cut[0] = _createFacetCut(diamondLoupeF, "DiamondLoupeFacet");
        cut[1] = _createFacetCut(ownershipF, "OwnershipFacet");
        cut[2] = _createFacetCut(staffManagementF, "StaffManagementFacet");
        cut[3] = _createFacetCut(inventoryManagementF, "InventoryManagementFacet");
        cut[4] = _createFacetCut(salesF, "SalesFacet");

        IDiamondCut(address(diamond)).diamondCut(cut, address(diamondInit), diamondInitCalldata);

        diamondAddr = address(diamond);

        diamondContracts.push(diamondAddr);
        index = diamondContracts.length;

        emit DiamondDeployed(diamondAddr, index);
    }

    function getDiamondContract(uint256 index) external view returns (address) {
        require(index > 0 && index <= diamondContracts.length, InvalidIndex());
        return diamondContracts[index - 1];
    }

    function _createFacetCut(address _facetAddress, string memory _facetName)
        private
        view
        returns (IDiamondCut.FacetCut memory)
    {
        return IDiamondCut.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: SelectorGenerator.generateSelectors(_facetAddress, _facetName)
        });
    }
}
