// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * \
 * Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 * /*****************************************************************************
 */
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    // Diamond errors
    error NotDiamondOwner();
    error NotProposedOwner();
    error InValidFacetCutAction();
    error NoSelectorsInFacet();
    error SelectorExists(bytes4 selector);
    error NoZeroAddress();
    error MustBeZeroAddress();
    error ImmutableFunction(bytes4 selector);
    error SameSelectorReplacement(bytes4 selector);
    error NonExistentSelector(bytes4 selector);
    error NonEmptyCalldata();
    error EmptyCalldata();
    error InitCallFailed();
    error NoCode();

    // Global custom errors
    error NotSalesRep();
    error NotStoreOwner();
    error NotActiveStaff();
    error NotAnAdministrator();
    error NotSalesRepOrAdministrator();
    error ProductDoesNotExist(uint256 productId);
    error ProductOutOfStock(uint256 productId);
    error InsufficientStock(uint256 productId, uint256 requested, uint256 available);

    // Events
    event OwnershipTransferRequested(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferAccepted(address indexed previousOwner, address indexed newOwner);
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);
    event ProductStockIsLow(uint256 indexed productID, uint256 quantity);

    // Storage positions
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");
    bytes32 constant STORE_STATE_POSITION = keccak256("diamond.standard.store.storage");
    bytes32 constant STAFF_STATE_POSITION = keccak256("diamond.standard.staff.storage");

    /**
     * @dev Diamond storage
     */
    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
        // proposed owner
        address newOwner;
        string storeDetailsIPFSHash;
    }

    /**
     * Store storage
     */
    enum ModeOfPayment {
        POS,
        Cash,
        BankTransfer
    }

    struct SaleItem {
        uint256 productId;
        uint256 quantity;
    }

    struct Sale {
        SaleItem[] items;
        uint256 totalAmount;
        uint256 timestamp;
        address cashierId;
        ModeOfPayment paymentMode;
    }

    struct Product {
        uint256 productId;
        string productName;
        uint256 productPrice;
        uint256 quantity;
        uint256 dateAdded;
        string barcode;
        address uploader;
        uint16 productLowMargin;
    }

    struct StoreState {
        uint256 saleCounter; // Counter to track the sale ID
        mapping(uint256 => Sale) sales; // Mapping of sale ID to Sale struct
        uint256 productCounter; // Counter to track the products ID
        mapping(uint256 => Product) products; // Mapping of productId to products struct
        uint256[] productsIDArray;
        uint256 maximumQuantity;
    }

    /**
     * Staff storage
     */
    enum Role {
        Administrator,
        SalesRep
    }

    enum Status {
        Active,
        Inactive,
        Removed
    }

    struct Staff {
        uint256 staffID;
        string name;
        string email;
        uint256 phoneNumber;
        Status status;
        uint256 dateJoined;
        Role role;
    }

    struct StaffState {
        uint16 maxAdmins; // Max number of admins allowed (set by store owner)
        uint32 adminCount; // To track the number of administrators
        address proposedOwner; // Proposed new owner
        mapping(address => Staff) staffDetails; // Mapping to store staff details by their address
        mapping(uint256 => address) staffIDToAddress; // Mapping to store staffID to their address
        address[] staffAddressArray; // Array of staffID
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // Function to retrieve staff storage
    function getStaffState() internal pure returns (StaffState storage staffState) {
        bytes32 position = STAFF_STATE_POSITION;
        assembly {
            staffState.slot := position
        }
    }

    // Function to retrieve store storage
    function getStoreState() internal pure returns (StoreState storage storeState) {
        bytes32 position = STORE_STATE_POSITION;
        assembly {
            storeState.slot := position
        }
    }

    function setInitials(address storeOwner, uint16 maxAdmins, uint24 maxQuantity) internal {
        StaffState storage staffState = getStaffState();
        staffState.maxAdmins = maxAdmins;

        StoreState storage state = getStoreState();
        state.maximumQuantity = maxQuantity;

        DiamondStorage storage ds = diamondStorage();
        ds.newOwner = storeOwner;
    }

    function deleteStaffIDFromArray(address _staffAddr) internal {
        StaffState storage staffState = getStaffState();
        address[] memory _staffsAddresses = staffState.staffAddressArray;
        uint256 staffsCount = _staffsAddresses.length;
        for (uint256 i = 0; i < staffsCount; i++) {
            if (_staffsAddresses[i] == _staffAddr) {
                staffState.staffAddressArray[i] = _staffsAddresses[staffsCount - 1];
                staffState.staffAddressArray.pop();
                break;
            }
        }
    }

    function deleteProductIdFromArray(uint256 _productId) internal {
        StoreState storage store = getStoreState();
        uint256[] memory productsIDs = store.productsIDArray;
        uint256 noOfProducts = productsIDs.length;
        for (uint256 i = 0; i < noOfProducts; i++) {
            if (productsIDs[i] == _productId) {
                store.productsIDArray[i] = productsIDs[noOfProducts - 1];
                store.productsIDArray.pop();
                break;
            }
        }
    }

    function setContractOwner(address _owner) internal {
        diamondStorage().contractOwner = _owner;
    }

    function transferOwnership(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.newOwner = _newOwner;
        emit OwnershipTransferRequested(previousOwner, _newOwner);
    }

    function acceptOwnership() internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = msg.sender;
        ds.newOwner = address(0);
        emit OwnershipTransferAccepted(previousOwner, msg.sender);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function updateStoreDetails(string calldata newHash) internal {
        diamondStorage().storeDetailsIPFSHash = newHash;
    }

    function enforceIsContractOwner() internal view {
        if (msg.sender != diamondStorage().contractOwner) {
            revert NotDiamondOwner();
        }
    }

    function enforceIsProposedOwner() internal view {
        if (msg.sender != diamondStorage().newOwner) {
            revert NotProposedOwner();
        }
    }

    // Internal function version of diamondCut
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert InValidFacetCutAction();
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) revert NoZeroAddress();
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) revert SelectorExists(selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) revert NoZeroAddress();
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress == _facetAddress) {
                revert SameSelectorReplacement(selector);
            }
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        if (_facetAddress != address(0)) revert MustBeZeroAddress();
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress);
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress)
        internal
    {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        if (_facetAddress == address(0)) revert NonExistentSelector(_selector);
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) revert ImmutableFunction(_selector);
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            if (_calldata.length > 0) revert NonEmptyCalldata();
        } else {
            if (_calldata.length == 0) revert EmptyCalldata();
            if (_init != address(this)) {
                enforceHasContractCode(_init);
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert InitCallFailed();
                }
            }
        }
    }

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize <= 0) revert NoCode();
    }
}
