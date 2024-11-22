// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { LibDiamond } from "../libraries/LibDiamond.sol";

interface ISales {
    function recordSale(LibDiamond.SaleItem[] calldata items, uint256 totalAmount, LibDiamond.ModeOfPayment paymentMode)
        external
        returns (uint256);

    function getTotalSales() external view returns (uint256);
}
