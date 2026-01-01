// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILendingPoolV2} from "contracts/interfaces/ILendingPoolV2.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {AaveWrapperV2} from "contracts/wrappers/AaveWrapperV2.sol";

/// @notice Deploys an AaveWrapperV2 and adds it to MultiWrapper; markets passed via env.
contract DeployAaveWrapperV2 is Script {
    function run() external returns (AaveWrapperV2 wrapper) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle offchainOracle = OffchainOracle(aggregator);
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();
        address pool =
            vm.parseJsonAddress(json, string.concat(chainKey, ".wrappers[", vm.toString(index), "].env.pool"));
        address[] memory markets =
            vm.parseJsonAddressArray(json, string.concat(chainKey, ".wrappers[", vm.toString(index), "].env.markets"));

        vm.startBroadcast();
        wrapper = new AaveWrapperV2(ILendingPoolV2(pool));
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
