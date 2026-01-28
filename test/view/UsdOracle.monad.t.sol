// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {RpcUtils} from "test/utils/RpcUtils.sol";
import {UsdOracle} from "contracts/view/UsdOracle.sol";

contract UsdOracleMonadTest is RpcUtils {
    UsdOracle public oracle;

    address private constant WBASE = 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A;

    address public usdc;
    address public usdt;
    address public weth;
    address public wbtc;

    function setUp() public {
        vm.createSelectFork(_rpcUrl("monad"));

        string memory json = vm.readFile("config.json");
        string memory chainKey = ".143";
        string memory aggregatorRaw = vm.parseJsonString(json, string.concat(chainKey, ".aggregator"));
        require(bytes(aggregatorRaw).length != 0, "missing aggregator for chain 143");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        require(aggregator != address(0), "aggregator is zero for chain 143");
        address[] memory tokens = vm.parseJsonAddressArray(json, string.concat(chainKey, ".env.tokens"));
        address[] memory feeds = vm.parseJsonAddressArray(json, string.concat(chainKey, ".env.feeds"));
        require(tokens.length >= 4, "tokens length < 4");
        require(feeds.length == tokens.length + 2, "feeds length must be tokens+2");

        address[] memory deployTokens = new address[](tokens.length + 2);
        deployTokens[0] = address(0);
        deployTokens[1] = WBASE;
        for (uint256 i = 0; i < tokens.length; i++) {
            deployTokens[i + 2] = tokens[i];
        }

        oracle = new UsdOracle(aggregator, deployTokens, feeds);

        weth = tokens[0];
        usdt = tokens[1];
        usdc = tokens[2];
        wbtc = tokens[3];
    }

    function testUsd_usdc() public view {
        (uint256 price,) = oracle.usd(usdc);
        assertGt(price, 0.9e18);
        assertLt(price, 1.1e18);
    }

    function testUsd_usdt() public view {
        (uint256 price,) = oracle.usd(usdt);
        assertGt(price, 0.9e18);
        assertLt(price, 1.1e18);
    }

    function testUsd_weth() public view {
        (uint256 price,) = oracle.usd(weth);
        assertGt(price, 100e18);
        assertLt(price, 10_000e18);
    }

    function testUsd_wbtc() public view {
        (uint256 price,) = oracle.usd(wbtc);
        assertGt(price, 1000e18);
        assertLt(price, 1_000_000e18);
    }
}
