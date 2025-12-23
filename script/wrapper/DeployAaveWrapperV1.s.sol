// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {AaveWrapperV1} from "contracts/wrappers/AaveWrapperV1.sol";

/// @notice Deploys an AaveWrapperV1 and adds it to MultiWrapper; markets passed via env.
contract DeployAaveWrapperV1 is Script {
    function run() external returns (AaveWrapperV1 wrapper) {
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle offchainOracle = OffchainOracle(aggregator);
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();
        address[] memory markets =
            vm.parseJsonAddressArray(json, string.concat(chainKey, ".wrappers[", vm.toString(index), "].env.markets"));

        vm.startBroadcast();
        wrapper = new AaveWrapperV1{salt: salt}();
        wrapper.addMarkets(_toIERC20(markets));
        multiWrapper.addWrapper(wrapper);
        vm.stopBroadcast();
    }

    function _toIERC20(address[] memory addrs) private pure returns (IERC20[] memory tokens) {
        tokens = new IERC20[](addrs.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            tokens[i] = IERC20(addrs[i]);
        }
    }
}
