// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { LibDiamond } from "../libraries/LibDiamond.sol";

contract InventoryManagementFacet {
    // Custom errors
    error ProductExist(uint256 productId);
    error EmptyProductName();
    error InvalidPrice();
    error InvalidQuantity();
    error MaximumQuantityExceeded();

    // Events
    event ProductAdded(
        uint256 indexed productID,
        string productName,
        uint256 productPrice,
        uint256 quantity,
        address indexed uploader,
        uint256 dateAdded
    );
    event ProductUpdated(uint256 indexed productID, string productName, uint256 productPrice, string barcode);
    event ProductDeleted(uint256 indexed productID);
    event ProductRestocked(uint256 indexed productID, uint256 amountRestocked, uint256 currentStock);

    modifier onlyAdmin() {
        require(msg.sender != address(0), LibDiamond.NoZeroAddress());
        LibDiamond.StaffState storage staffState = LibDiamond.getStaffState();
        LibDiamond.Staff memory caller = staffState.staffDetails[msg.sender];
        require(caller.role == LibDiamond.Role.Administrator, LibDiamond.NotAnAdministrator());
        require(caller.status == LibDiamond.Status.Active, LibDiamond.NotActiveStaff());
        _;
    }

    modifier onlyAdminAndSalesRep() {
        LibDiamond.StaffState storage staffState = LibDiamond.getStaffState();
        LibDiamond.Staff memory caller = staffState.staffDetails[msg.sender];
        require(
            caller.role == LibDiamond.Role.SalesRep || caller.role == LibDiamond.Role.Administrator,
            LibDiamond.NotSalesRepOrAdministrator()
        );
        require(caller.status == LibDiamond.Status.Active, LibDiamond.NotActiveStaff());
        _;
    }

    function addNewProduct(
        uint256 _productID,
        string calldata _productName,
        uint256 _productPrice,
        uint256 _quantity,
        string calldata _barcode
    ) external onlyAdmin {
        if (bytes(_productName).length == 0) revert EmptyProductName();
        if (_productPrice <= 0) revert InvalidPrice();

        string memory barcode = bytes(_barcode).length > 0 ? _barcode : "";

        LibDiamond.StoreState storage state = LibDiamond.getStoreState();
        mapping(uint256 => LibDiamond.Product) storage products = state.products;
        if (_quantity > state.maximumQuantity) revert InvalidQuantity();

        if (products[_productID].uploader != address(0)) revert ProductExist(_productID);

        state.productsIDArray.push(_productID);
        state.products[_productID] = LibDiamond.Product({
            productId: _productID,
            productName: _productName,
            productPrice: _productPrice,
            quantity: _quantity,
            uploader: msg.sender,
            dateAdded: block.timestamp,
            barcode: barcode
        });

        emit ProductAdded(_productID, _productName, _productPrice, _quantity, msg.sender, block.timestamp);
    }

    function updateProduct(
        uint256 _productID,
        string calldata _productName,
        uint256 _productPrice,
        string calldata _barcode
    ) external onlyAdmin {
        if (bytes(_productName).length == 0) revert EmptyProductName();
        if (_productPrice <= 0) revert InvalidPrice();

        string memory barcode = bytes(_barcode).length > 0 ? _barcode : "";

        LibDiamond.StoreState storage state = LibDiamond.getStoreState();
        LibDiamond.Product storage product = state.products[_productID];
        if (product.uploader == address(0)) revert LibDiamond.ProductDoesNotExist(_productID);

        product.productName = _productName;
        product.productPrice = _productPrice;
        product.barcode = barcode;

        emit ProductUpdated(_productID, _productName, _productPrice, _barcode);
    }

    function restockProduct(LibDiamond.SaleItem[] calldata _products) external onlyAdmin {
        LibDiamond.StoreState storage state = LibDiamond.getStoreState();
        uint256 productsLength = _products.length;
        for (uint256 i; i < productsLength;) {
            uint256 productID = _products[i].productId;
            uint256 quantity = _products[i].quantity;

            if (quantity == 0 || quantity > state.maximumQuantity) revert InvalidQuantity();

            LibDiamond.Product storage product = state.products[productID];
            if (product.uploader == address(0)) revert LibDiamond.ProductDoesNotExist(productID);
            // Check for overflow
            uint256 newQuantity = product.quantity + quantity;
            if (newQuantity > state.maximumQuantity) revert MaximumQuantityExceeded();

            product.quantity = newQuantity;
            emit ProductRestocked(productID, quantity, newQuantity);

            unchecked {
                ++i;
            }
        }
    }

    function getAllProducts() external view returns (LibDiamond.Product[] memory) {
        LibDiamond.StoreState storage state = LibDiamond.getStoreState();
        uint256[] memory productIds = state.productsIDArray;
        uint256 noOfProducts = productIds.length;

        LibDiamond.Product[] memory allProducts = new LibDiamond.Product[](noOfProducts);
        for (uint256 i; i < noOfProducts;) {
            allProducts[i] = state.products[productIds[i]];
            unchecked {
                ++i;
            }
        }
        return allProducts;
    }

    function deleteProduct(uint256 _productID) external onlyAdmin {
        LibDiamond.StoreState storage state = LibDiamond.getStoreState();
        if (state.products[_productID].uploader == address(0)) revert LibDiamond.ProductDoesNotExist(_productID);

        LibDiamond.deleteProductIdFromArray(_productID);
        delete state.products[_productID];
        emit ProductDeleted(_productID);
    }
}
