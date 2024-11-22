// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script, console } from "../lib/forge-std/src/Script.sol";
import { IDiamondFactory } from "../src/interfaces/IDiamondFactory.sol";

contract DeployViaFactory is Script {
    uint256 deployerPrivateKey = vm.envUint("DO_NOT_LEAK");
    address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
    address storeOwner = vm.envAddress("STORE_OWNER");
    uint16 maxAdmins = uint16(vm.envUint("MAX_ADMIN"));
    uint24 maxQuantity = uint24(vm.envUint("MAX_QUANTITY"));

    function deploy() internal returns (address) {
        // Start broadcast
        vm.startBroadcast(deployerPrivateKey);

        IDiamondFactory factory = IDiamondFactory(factoryAddress);

        // Deploy through factory
        (address deployed,) = factory.deployDiamond(storeOwner, maxAdmins, maxQuantity);

        // End broadcast
        vm.stopBroadcast();
        return deployed;
    }

    function run() external {
        address deployedDiamondAddress = deploy();

        // Make script executable
        string[] memory scriptPermissionArgs = new string[](3);
        scriptPermissionArgs[0] = "chmod";
        scriptPermissionArgs[1] = "+x";
        scriptPermissionArgs[2] = "script/helpers/verify-contract.sh";
        vm.ffi(scriptPermissionArgs);

        string[] memory verifyArgs = new string[](3);
        verifyArgs[0] = "script/helpers/verify-contract.sh";
        verifyArgs[1] = vm.toString(deployedDiamondAddress);
        verifyArgs[2] = "src/Diamond.sol:Diamond";

        // Execute verification and log result
        try vm.ffi(verifyArgs) returns (bytes memory result) {
            string memory output = string(result);
            console.log("Contract verified successfully!");
            console.log(output);
        } catch (bytes memory err) {
            string memory errorMsg = string(err);
            console.log("Verification failed with error:");
            console.log(errorMsg);
        }
    }
}
