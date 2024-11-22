// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { LibDiamond } from "../libraries/LibDiamond.sol";

interface IInventoryManagement {
    function addNewProduct(
        uint256 _productID,
        string calldata _productName,
        uint256 _productPrice,
        uint256 _quantity,
        uint16 _productLowMargin,
        string calldata _barcode
    ) external;

    function updateProductName(uint256 _productID, string calldata _productName) external;

    function updateProductPrice(uint256 _productID, uint256 _productPrice) external;

    function updateProductLowMargin(uint256 _productID, uint16 _productLowMargin) external;

    function restockProduct(LibDiamond.SaleItem[] calldata _products) external;

    function getAllProducts() external view returns (LibDiamond.Product[] memory);

    function deleteProduct(uint256 _productID) external;
}
