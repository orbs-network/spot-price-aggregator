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
        OffchainOracle offchainOracle = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();

        address comptroller = vm.envAddress("COMPTROLLER");
        address cBase = vm.envAddress("CBASE");
        address[] memory markets = vm.envAddress("MARKETS", ",");

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
