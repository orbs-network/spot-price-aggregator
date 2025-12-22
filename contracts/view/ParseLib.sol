// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @notice Parsing helpers for view-only USD oracles.
library ParseLib {
    /// @notice Parses a decimal string into a uint256 scaled to 1e18 (truncates beyond 18 decimals).
    /// @param rate Decimal string from the precompile (for example "1.2345").
    /// @return Parsed value scaled to 1e18.
    function parse1e18(string memory rate) internal pure returns (uint256) {
        bytes memory b = bytes(rate);
        uint256 dot = b.length;
        for (uint256 i; i < b.length; i++) {
            if (b[i] == bytes1(".")) {
                dot = i;
                break;
            }
        }

        uint256 intPart = Strings.parseUint(rate, 0, dot);
        if (dot == b.length) return intPart * 1e18;

        uint256 fracStart = dot + 1;
        uint256 fracLen = b.length - fracStart;
        if (fracLen > 18) fracLen = 18;
        if (fracLen == 0) return intPart * 1e18;
        uint256 frac = Strings.parseUint(rate, fracStart, fracStart + fracLen);
        if (fracLen < 18) frac *= 10 ** (18 - fracLen);

        return intPart * 1e18 + frac;
    }
}
