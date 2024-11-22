// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { ISales } from "../interfaces/ISales.sol";

contract SalesFacet is ISales {
    error NoItemsInSale();
    error InvalidRange();

    event SaleRecorded(
        uint256 saleId,
        address indexed cashierId,
        uint256 indexed totalAmount,
        uint256 indexed timestamp,
        LibDiamond.ModeOfPayment paymentMode
    );

    modifier onlySalesRep() {
        LibDiamond.Staff memory caller = LibDiamond.getStaffState().staffDetails[msg.sender];
        require(caller.role == LibDiamond.Role.SalesRep, LibDiamond.NotSalesRep());
        require(caller.status == LibDiamond.Status.Active, LibDiamond.NotActiveStaff());
        _;
    }

    modifier onlyAdminAndSalesRep() {
        LibDiamond.Staff memory caller = LibDiamond.getStaffState().staffDetails[msg.sender];
        require(
            caller.role == LibDiamond.Role.SalesRep || caller.role == LibDiamond.Role.Administrator,
            LibDiamond.NotSalesRepOrAdministrator()
        );
        require(caller.status == LibDiamond.Status.Active, LibDiamond.NotActiveStaff());
        _;
    }

    function recordSale(LibDiamond.SaleItem[] calldata items, uint256 totalAmount, LibDiamond.ModeOfPayment paymentMode)
        external
        onlySalesRep
        returns (uint256)
    {
        require(items.length > 0, NoItemsInSale());

        LibDiamond.StoreState storage state = LibDiamond.getStoreState();

        // Increment sale ID and create new sale
        uint256 saleId = state.saleCounter++;
        LibDiamond.Sale storage newSale = state.sales[saleId];
        newSale.timestamp = block.timestamp;
        newSale.totalAmount = totalAmount;
        newSale.cashierId = msg.sender;
        newSale.paymentMode = paymentMode;

        // Emit SaleRecorded event with specified indexed fields
        emit SaleRecorded(saleId, msg.sender, totalAmount, block.timestamp, paymentMode);

        // Directly assign the items array to newSale.items and reduce product count
        for (uint256 i = 0; i < items.length;) {
            newSale.items.push(items[i]);
            _reduceProductCount(items[i].productId, items[i].quantity);
            unchecked {
                ++i;
            }
        }

        return saleId;
    }

    function getTotalSales() external view onlyAdminAndSalesRep returns (uint256) {
        LibDiamond.StoreState storage state = LibDiamond.getStoreState();
        return state.saleCounter;
    }

    function _reduceProductCount(uint256 productId, uint256 quantity) private {
        LibDiamond.Product storage product = LibDiamond.getStoreState().products[productId];
        uint256 availableStock = product.quantity;

        if (product.uploader == address(0)) revert LibDiamond.ProductDoesNotExist(productId);
        if (availableStock == 0) revert LibDiamond.ProductOutOfStock(productId);
        if (availableStock < quantity) revert LibDiamond.InsufficientStock(productId, quantity, availableStock);

        product.quantity -= quantity;

        if ((availableStock - quantity) <= product.productLowMargin) {
            emit LibDiamond.ProductStockIsLow(productId, (availableStock - quantity));
        }
    }
}
