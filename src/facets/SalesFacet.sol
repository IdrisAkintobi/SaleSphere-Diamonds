// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { LibDiamond } from "../libraries/LibDiamond.sol";

contract SalesFacet {
    error NoItemsInSale();

    event SaleRecorded(
        uint256 saleId,
        address indexed cashierId,
        uint256 indexed totalAmount,
        uint256 indexed timestamp,
        LibDiamond.ModeOfPayment paymentMode
    );

    modifier onlySalesRep() {
        LibDiamond.StaffState storage staffState = LibDiamond.getStaffState();
        LibDiamond.Staff memory caller = staffState.staffDetails[msg.sender];
        require(caller.role == LibDiamond.Role.SalesRep, LibDiamond.NotSalesRep());
        require(caller.status == LibDiamond.Status.Active, LibDiamond.NotActiveStaff());
        _; // continue execution
    }

    function recordSale(LibDiamond.SaleItem[] calldata items, uint256 totalAmount, LibDiamond.ModeOfPayment paymentMode)
        external
        onlySalesRep
    {
        require(items.length > 0, NoItemsInSale());

        LibDiamond.StoreState storage state = LibDiamond.getStoreState();

        // Increment sale ID and create new sale
        state.saleCounter++;
        LibDiamond.Sale storage newSale = state.sales[state.saleCounter];
        newSale.timestamp = block.timestamp;
        newSale.totalAmount = totalAmount;
        newSale.cashierId = msg.sender;
        newSale.paymentMode = paymentMode;

        // Directly assign the items array to newSale.items and reduce product count
        for (uint256 i = 0; i < items.length; i++) {
            newSale.items.push(items[i]);
            _reduceProductCount(items[i].productId, items[i].quantity);
        }

        // Emit SaleRecorded event with specified indexed fields
        emit SaleRecorded(state.saleCounter, msg.sender, totalAmount, block.timestamp, paymentMode);
    }

    function getAllSalesDisplay(uint256 startIndex, uint256 endIndex)
        external
        view
        returns (LibDiamond.SaleDisplay[] memory)
    {
        LibDiamond.StoreState storage state = LibDiamond.getStoreState();
        LibDiamond.StaffState storage staffState = LibDiamond.getStaffState();

        require(startIndex <= endIndex && endIndex <= state.saleCounter, "Invalid range");

        // Calculate total number of items across all requested sales
        uint256 totalItems = 0;
        for (uint256 i = startIndex; i <= endIndex; i++) {
            totalItems += state.sales[i].items.length;
        }

        LibDiamond.SaleDisplay[] memory displaySales = new LibDiamond.SaleDisplay[](totalItems);
        uint256 currentIndex = 0;

        // Process each sale
        for (uint256 saleIndex = startIndex; saleIndex <= endIndex; saleIndex++) {
            LibDiamond.Sale storage sale = state.sales[saleIndex];

            // Process each item in the sale
            for (uint256 itemIndex = 0; itemIndex < sale.items.length; itemIndex++) {
                LibDiamond.SaleItem storage item = sale.items[itemIndex];
                LibDiamond.Product storage product = state.products[item.productId];
                LibDiamond.Staff storage cashier = staffState.staffDetails[sale.cashierId];

                displaySales[currentIndex] = LibDiamond.SaleDisplay({
                    saleId: string(abi.encodePacked(saleIndex, itemIndex)),
                    productName: product.productName,
                    productPrice: product.productPrice,
                    quantity: item.quantity,
                    seller: cashier.name,
                    modeOfPayment: sale.paymentMode
                });

                currentIndex++;
            }
        }

        return displaySales;
    }

    function getTotalSales() external view returns (uint256) {
        LibDiamond.StoreState storage state = LibDiamond.getStoreState();
        return state.saleCounter;
    }

    function getSalesRepTotalSales() external view returns (string[] memory salesReps, uint256[] memory totalSales) {
        LibDiamond.StoreState storage state = LibDiamond.getStoreState();
        LibDiamond.StaffState storage staffState = LibDiamond.getStaffState();

        // Get unique sales reps and count them
        uint256 repCount;
        address[] memory uniqueReps = new address[](state.saleCounter);
        for (uint256 i = 0; i < state.saleCounter; i++) {
            address cashierAddress = state.sales[i].cashierId;
            bool isUnique = true;
            for (uint256 j = 0; j < repCount; j++) {
                if (uniqueReps[j] == cashierAddress) {
                    isUnique = false;
                    break;
                }
            }
            if (isUnique) {
                uniqueReps[repCount++] = cashierAddress;
            }
        }

        // Populate arrays
        salesReps = new string[](repCount);
        totalSales = new uint256[](repCount);

        for (uint256 i = 0; i < repCount; i++) {
            salesReps[i] = staffState.staffDetails[uniqueReps[i]].name;
            totalSales[i] = 0;
            for (uint256 j = 0; j < state.saleCounter; j++) {
                if (state.sales[j].cashierId == uniqueReps[i]) {
                    totalSales[i]++;
                }
            }
        }

        return (salesReps, totalSales);
    }

    function _reduceProductCount(uint256 productId, uint256 quantity) internal {
        LibDiamond.StoreState storage state = LibDiamond.getStoreState();
        LibDiamond.Product storage product = state.products[productId];
        uint256 availableStock = product.quantity;

        if (product.uploader == address(0)) revert LibDiamond.ProductDoesNotExist(productId);
        if (availableStock == 0) revert LibDiamond.ProductOutOfStock(productId);
        if (availableStock < quantity) revert LibDiamond.InsufficientStock(productId, quantity, availableStock);

        product.quantity -= quantity;

        if ((availableStock - quantity) <= state.productLowMargin) {
            emit LibDiamond.ProductStockIsLow(productId, (availableStock - quantity));
        }
    }
}
