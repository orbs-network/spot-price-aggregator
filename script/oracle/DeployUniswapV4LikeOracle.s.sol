// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {UniswapV4LikeOracle} from "contracts/oracles/UniswapV4LikeOracle.sol";
import {IUniswapV4StateView} from "contracts/interfaces/IUniswapV4StateView.sol";

contract DeployUniswapV4LikeOracle is Script {
    function run() external returns (UniswapV4LikeOracle oracle) {
        OffchainOracle oc = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address stateView = vm.envAddress("STATEVIEW");
        uint256[] memory feesRaw = vm.envUint("FEES", ","); // uint24[]
        uint256[] memory spacingsRaw = vm.envUint("SPACINGS", ","); // int24[]
        uint24[] memory fees = _toUint24(feesRaw);
        int24[] memory spacings = _toInt24(spacingsRaw);
        uint256 oracleType = vm.envOr("TYPE", uint256(0)); // AMM defaults to WETH

        vm.startBroadcast();
        oracle = new UniswapV4LikeOracle{salt: salt}(IUniswapV4StateView(stateView), fees, spacings);
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }

    function _toUint24(uint256[] memory src) private pure returns (uint24[] memory dst) {
        dst = new uint24[](src.length);
        for (uint256 i = 0; i < src.length; i++) {
            dst[i] = uint24(src[i]);
        }
    }

    function _toInt24(uint256[] memory src) private pure returns (int24[] memory dst) {
        dst = new int24[](src.length);
        for (uint256 i = 0; i < src.length; i++) {
            dst[i] = int24(int256(src[i]));
        }
    }
}
