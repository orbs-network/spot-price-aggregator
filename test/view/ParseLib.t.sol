// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {ParseLib} from "contracts/view/ParseLib.sol";

contract ParseLibTest is Test {
    function testParse1e18_basic() public pure {
        uint256 parsed = ParseLib.parse1e18("1234.23456789");
        assertEq(parsed, 1234_234_567_890_000_000_000); // 1234.23456789 * 1e18
    }

    function testParse1e18_truncatesLongFraction() public pure {
        uint256 parsed = ParseLib.parse1e18("1234.1234567890123456789");
        assertEq(parsed, 1234_123_456_789_012_345_678); // truncates to 18 decimal places
    }

    function testParse1e18_noDecimalPoint() public pure {
        uint256 parsed = ParseLib.parse1e18("42");
        assertEq(parsed, 42 * 1e18);
    }
}
