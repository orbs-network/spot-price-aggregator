// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";

import {OracleSei} from "contracts/OracleSei.sol";

contract DeployOracleSei is Script {
    address private constant _USDC = 0xe15fC38F6D8c56aF07bbCBe3BAf5708A2Bf42392;
    address private constant _USDT = 0xB75D0B03c06A926e488e2659DF1A861F860bD3d1;
    address private constant _WETH = 0x160345fC359604fC6e70E3c5fAcbdE5F7A9342d8;
    address private constant _WBTC = 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c;
    address private constant _SEI = address(0);
    address private constant _WSEI = 0xE30feDd158A2e3b13e9badaeABaFc5516e95e8C7;

    function run() external returns (OracleSei oracleSei) {
        address oracle = vm.envOr("ORACLE", address(0));
        if (oracle == address(0)) {
            string memory json = vm.readFile("script/config.json");
            string memory key = string.concat(".", vm.toString(block.chainid), ".oracle");
            oracle = vm.parseJsonAddress(json, key);
        }
        uint256 threshold = vm.envOr("THRESHOLD", uint256(90));
        bytes32 salt = vm.envOr("SALT", bytes32(0x374eb1cf3455289c1707dd0eabb21e6b757f37a905b2437f3b549bbbbe16c433));

        (address[] memory tokens, string[] memory denoms) = _tokensAndDenoms();

        vm.startBroadcast();
        console.logBytes32(hashInitCode(type(OracleSei).creationCode, abi.encode(oracle, threshold, tokens, denoms)));
        oracleSei = new OracleSei{salt: salt}(oracle, threshold, tokens, denoms);
        vm.stopBroadcast();
    }

    function _tokensAndDenoms() private view returns (address[] memory tokens, string[] memory denoms) {
        string memory tokensEnv = vm.envOr("TOKENS", string(""));
        string memory denomsEnv = vm.envOr("DENOMS", string(""));

        if (bytes(tokensEnv).length != 0 || bytes(denomsEnv).length != 0) {
            tokens = vm.envAddress("TOKENS", ",");
            denoms = vm.envString("DENOMS", ",");
            return (tokens, denoms);
        }

        // Default Sei mapping.
        // NOTE: `tokens[0]` becomes the base token used for offchain-oracle conversion in `usd(token)`.
        tokens = new address[](6);
        denoms = new string[](6);

        tokens[0] = _USDC;
        denoms[0] = "uusdc";

        tokens[1] = _USDT;
        denoms[1] = "uusdt";

        tokens[2] = _WETH;
        denoms[2] = "ueth";

        tokens[3] = _WBTC;
        denoms[3] = "ubtc";

        tokens[4] = _SEI;
        denoms[4] = "usei";

        tokens[5] = _WSEI;
        denoms[5] = "usei";
    }
}
