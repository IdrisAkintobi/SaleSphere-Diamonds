// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

pragma solidity 0.8.28;

import { Test } from "../../lib/forge-std/src/Test.sol";
import { Script } from "../../lib/forge-std/src/Script.sol";
import { console } from "../../lib/forge-std/src/console.sol";
import "../../lib/solidity-stringutils/src/strings.sol";

abstract contract DiamondUtils is Script {
    using strings for *;

    function generateSelectors(string memory _facetName) internal returns (bytes4[] memory selectors) {
        // Execute forge inspect command
        string[] memory cmd = new string[](4);
        cmd[0] = "forge";
        cmd[1] = "inspect";
        cmd[2] = _facetName;
        cmd[3] = "methods";
        bytes memory res = vm.ffi(cmd);
        string memory output = string(res);

        // Convert output to slice
        strings.slice memory s = output.toSlice();
        strings.slice memory nl = "\n".toSlice();
        strings.slice memory pipe = "|".toSlice();

        // Skip header (First 2 lines are table headers)
        s.split(nl);
        s.split(nl);

        // Determine number of methods
        uint256 methodCount = s.count(nl);
        selectors = new bytes4[](methodCount / 2);

        for (uint256 i = 0; i < selectors.length; i++) {
            s.split(nl); // Move to next method row
            // Skip first and second pipe (method name)
            s.split(pipe);
            s.split(pipe);

            // Extract function selector from Identifier column
            strings.slice memory identifierSlice = s.split(pipe);
            string memory identifier = identifierSlice.toString();

            // Convert hex string to bytes4
            selectors[i] = parseHexString(trim(identifier));

            // Skip the next line
            s.split(nl);
        }

        return selectors;
    }

    // Manual trim function to remove leading and trailing spaces
    function trim(string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        uint256 start = 0;
        uint256 end = strBytes.length;

        // Find first non-space character
        while (start < end && strBytes[start] == " ") {
            start++;
        }

        // Find last non-space character
        while (end > start && strBytes[end - 1] == " ") {
            end--;
        }

        // Create new string with trimmed content
        bytes memory trimmedBytes = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            trimmedBytes[i - start] = strBytes[i];
        }

        return string(trimmedBytes);
    }

    function parseHexString(string memory hexString) internal pure returns (bytes4) {
        bytes memory hexBytes = bytes(hexString);
        require(hexBytes.length == 8, "Invalid function selector length");

        uint32 selector;
        for (uint256 i = 0; i < 8; i++) {
            uint8 digit = uint8(hexBytes[i]);

            if (digit >= 48 && digit <= 57) {
                // '0' - '9'
                selector = (selector << 4) | (digit - 48);
            } else if (digit >= 97 && digit <= 102) {
                // 'a' - 'f'
                selector = (selector << 4) | (digit - 87);
            } else if (digit >= 65 && digit <= 70) {
                // 'A' - 'F'
                selector = (selector << 4) | (digit - 55);
            } else {
                revert("Invalid hex character");
            }
        }
        return bytes4(selector);
    }
}
