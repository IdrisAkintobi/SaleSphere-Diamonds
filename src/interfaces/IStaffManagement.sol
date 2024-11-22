// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { LibDiamond } from "../libraries/LibDiamond.sol";

interface IStaffManagement {
    // Function to update the max admin limit (only accessible by the store owner)
    function updateAdminLimit(uint16 _newLimit) external;

    // Function to add new staff (only accessible by the store owner)
    function addStaff(
        address _addr,
        uint256 _staffID,
        string memory _name,
        string memory _email,
        uint256 _phoneNumber,
        LibDiamond.Role _role
    ) external;

    function setRole(uint256 _staffID, LibDiamond.Role _role) external;

    function updateStaffStatus(uint256 _staffID, LibDiamond.Status _status) external;

    function getStaffDetailsByAddress(address _staffAddr) external view returns (LibDiamond.Staff memory);

    function getStaffDetailsByID(uint256 _staffID) external view returns (LibDiamond.Staff memory);

    function getAllStaff() external view returns (LibDiamond.Staff[] memory allStaffs);
}
