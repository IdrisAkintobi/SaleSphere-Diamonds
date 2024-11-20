// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { LibDiamond } from "../libraries/LibDiamond.sol";

contract StaffManagementFacet {
    // Custom errors
    error StaffIdMustBePositiveInteger();
    error StaffIdExist();
    error StaffAlreadyExist();
    error StaffNotFound(uint256 staffID);
    error InvalidRoleAssignment(uint256 staffID, LibDiamond.Role currentRole);
    error TooManyAdmins();
    error InvalidStaffID(uint256 staffID);
    error StaffIdAlreadyUsed();
    error CannotUpdateOwnStatus();

    event StaffAdded(uint256 indexed staffID, address indexed staffAddr, string name, LibDiamond.Role role);
    event StaffRemoved(uint256 indexed staffID, address indexed staffAddr);
    event RoleUpdated(uint256 indexed staffID, address indexed staffAddr, LibDiamond.Role newRole);
    event AdminLimitUpdated(uint256 newLimit);
    event NewOwnerProposed(address proposedOwner);
    event StaffStatusUpdated(uint256 indexed staffID, address indexed staffAddr, LibDiamond.Status newStatus);

    modifier onlyAdmin() {
        LibDiamond.StaffState storage staffState = LibDiamond.getStaffState();
        LibDiamond.Staff memory caller = staffState.staffDetails[msg.sender];
        require(caller.role == LibDiamond.Role.Administrator, LibDiamond.NotAnAdministrator());
        require(caller.status == LibDiamond.Status.Active, LibDiamond.NotActiveStaff());
        _;
    }

    modifier onlyContractOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    // Function to update the max admin limit (only accessible by the store owner)
    function updateAdminLimit(uint16 _newLimit) external onlyContractOwner {
        LibDiamond.StaffState storage staffState = LibDiamond.getStaffState();
        require(msg.sender == staffState.storeOwner, LibDiamond.NotStoreOwner());

        staffState.maxAdmins = _newLimit;
        emit AdminLimitUpdated(_newLimit);
    }

    // Function to add new staff (only accessible by the store owner)
    function addStaff(
        address _addr,
        uint256 _staffID,
        string memory _name,
        string memory _email,
        uint256 _phoneNumber,
        LibDiamond.Role _role
    ) external onlyContractOwner {
        LibDiamond.StaffState storage staffState = LibDiamond.getStaffState();
        require(msg.sender == staffState.storeOwner, LibDiamond.NotStoreOwner());

        require(_addr != address(0), LibDiamond.NoZeroAddress());
        require(_staffID > 0, StaffIdMustBePositiveInteger());
        require(staffState.staffIDToAddress[_staffID] == address(0), StaffIdAlreadyUsed());
        require(staffState.staffDetails[_addr].staffID == 0, StaffIdExist());

        staffState.staffDetails[_addr] = LibDiamond.Staff({
            staffID: _staffID,
            name: _name,
            email: _email,
            phoneNumber: _phoneNumber,
            status: LibDiamond.Status.Active, // Automatically set to Active (0) when added
            dateJoined: block.timestamp,
            role: _role
        });
        staffState.staffAddressArray.push(_addr);
        staffState.staffIDToAddress[_staffID] = _addr;

        if (_role == LibDiamond.Role.Administrator) {
            if (staffState.adminCount >= staffState.maxAdmins) revert TooManyAdmins();
            staffState.adminCount++;
        }

        emit StaffAdded(_staffID, _addr, _name, _role);
    }

    // Function to promote or demote staff (only accessible by store owner)
    function setRole(uint256 _staffID, LibDiamond.Role _role) external onlyContractOwner {
        LibDiamond.StaffState storage staffState = LibDiamond.getStaffState();
        require(msg.sender == staffState.storeOwner, LibDiamond.NotStoreOwner());

        address staffAddr = staffState.staffIDToAddress[_staffID];
        if (staffAddr == address(0)) revert StaffNotFound(_staffID);

        LibDiamond.Staff memory staff = staffState.staffDetails[staffAddr];

        if (_role == LibDiamond.Role.Administrator) {
            if (staffState.adminCount >= staffState.maxAdmins) revert TooManyAdmins();
            staffState.adminCount++;
        }

        if (staff.role == LibDiamond.Role.Administrator) {
            staffState.adminCount--;
        }

        staffState.staffDetails[staffAddr].role = _role;
        emit RoleUpdated(_staffID, staffAddr, _role);
    }

    // Function to update staff status (only accessible by Admin)
    function updateStaffStatus(uint256 _staffID, LibDiamond.Status _status) external onlyAdmin {
        LibDiamond.StaffState storage staffState = LibDiamond.getStaffState();

        address staffAddr = staffState.staffIDToAddress[_staffID];
        require(staffAddr != address(0), StaffNotFound(_staffID));

        if (staffAddr == msg.sender) revert CannotUpdateOwnStatus();

        staffState.staffDetails[staffAddr].status = _status;

        emit StaffStatusUpdated(_staffID, staffAddr, _status);
    }

    // Function to get all active staff (returns only those with "Active" status)
    function getAllActiveStaffs() public view returns (LibDiamond.Staff[] memory activeStaffs) {
        LibDiamond.StaffState storage staffState = LibDiamond.getStaffState();

        uint256 staffCount = staffState.staffAddressArray.length;
        uint256 activeCount = 0;

        for (uint256 i = 0; i < staffCount; i++) {
            address staffAddr = staffState.staffAddressArray[i];
            if (staffState.staffDetails[staffAddr].status == LibDiamond.Status.Active) {
                activeCount++;
            }
        }

        activeStaffs = new LibDiamond.Staff[](activeCount);
        uint256 index = 0;

        for (uint256 i = 0; i < staffCount; i++) {
            address staffAddr = staffState.staffAddressArray[i];
            if (staffState.staffDetails[staffAddr].status == LibDiamond.Status.Active) {
                activeStaffs[index] = staffState.staffDetails[staffAddr];
                index++;
            }
        }
    }

    // Function to get staff details by staff ID (accessible by SalesRep or Administrator)
    function getStaffDetailsByID(uint256 _staffID) public view returns (LibDiamond.Staff memory) {
        LibDiamond.StaffState storage staffState = LibDiamond.getStaffState();

        address staffAddr = staffState.staffIDToAddress[_staffID];
        if (staffAddr == address(0)) revert StaffNotFound(_staffID);

        LibDiamond.Staff memory staff = staffState.staffDetails[staffAddr];
        return staff;
    }

    // Function to get all staff details (accessible by SalesRep or Administrator)
    function getAllStaff() public view returns (LibDiamond.Staff[] memory allStaffs) {
        LibDiamond.StaffState storage staffState = LibDiamond.getStaffState();

        address[] memory staffIDAddresses = staffState.staffAddressArray;
        uint256 staffCount = staffIDAddresses.length;
        allStaffs = new LibDiamond.Staff[](staffCount);

        for (uint256 i = 0; i < staffCount; i++) {
            address addr = staffIDAddresses[i];
            allStaffs[i] = staffState.staffDetails[addr];
        }
    }
}
