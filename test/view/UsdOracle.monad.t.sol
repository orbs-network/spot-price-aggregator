// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {UsdOracle} from "contracts/view/UsdOracle.sol";

contract UsdOracleMonadTest is Test {
    UsdOracle public oracle;

    address public usdc;
    address public usdt;
    address public weth;
    address public wbtc;

    function setUp() public {
        vm.createSelectFork("https://rpc.monad.xyz");

        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = ".143";
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        uint256 ttl = vm.parseJsonUint(json, string.concat(chainKey, ".env.ttl"));
        address[] memory tokens = vm.parseJsonAddressArray(json, string.concat(chainKey, ".env.tokens"));
        address[] memory feeds = vm.parseJsonAddressArray(json, string.concat(chainKey, ".env.feeds"));

        oracle = new UsdOracle(aggregator, ttl, tokens, feeds);

        weth = tokens[2];
        usdt = tokens[3];
        usdc = tokens[4];
        wbtc = tokens[5];
    }

    function testUsd_usdc() public view {
        uint256 price = oracle.usd(usdc);
        assertGt(price, 0.9e18);
        assertLt(price, 1.1e18);
    }

    function testUsd_usdt() public view {
        uint256 price = oracle.usd(usdt);
        assertGt(price, 0.9e18);
        assertLt(price, 1.1e18);
    }

    function testUsd_weth() public view {
        uint256 price = oracle.usd(weth);
        assertGt(price, 100e18);
        assertLt(price, 10_000e18);
    }

    function testUsd_wbtc() public view {
        uint256 price = oracle.usd(wbtc);
        assertGt(price, 1000e18);
        assertLt(price, 1_000_000e18);
    }
}
