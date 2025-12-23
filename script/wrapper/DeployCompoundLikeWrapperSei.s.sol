// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {CompoundLikeWrapperSei} from "contracts/wrappers/CompoundLikeWrapperSei.sol";
import {ISeiComptroller} from "contracts/interfaces/ISeiComptroller.sol";
import {ICToken} from "contracts/interfaces/ICToken.sol";

contract DeployCompoundLikeWrapperSei is Script {
    function run() external returns (CompoundLikeWrapperSei wrapper) {
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle offchainOracle = OffchainOracle(aggregator);
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();

        address comptroller =
            vm.parseJsonAddress(json, string.concat(chainKey, ".wrappers[", vm.toString(index), "].env.comptroller"));
        address cBase =
            vm.parseJsonAddress(json, string.concat(chainKey, ".wrappers[", vm.toString(index), "].env.cbase"));
        address[] memory markets =
            vm.parseJsonAddressArray(json, string.concat(chainKey, ".wrappers[", vm.toString(index), "].env.markets"));

        vm.startBroadcast();
        wrapper = new CompoundLikeWrapperSei{salt: salt}(ISeiComptroller(comptroller), IERC20(cBase));
        wrapper.addMarkets(_toICToken(markets));
        multiWrapper.addWrapper(wrapper);
        vm.stopBroadcast();
    }

    function _toICToken(address[] memory addrs) private pure returns (ICToken[] memory tokens) {
        tokens = new ICToken[](addrs.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            tokens[i] = ICToken(addrs[i]);
        }
    }
}
