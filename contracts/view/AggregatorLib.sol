// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @notice Shared pricing helpers for the view-only USD oracles.
/// @dev Intended for off-chain reads; not suitable for on-chain pricing.
library AggregatorLib {
    using Math for uint256;

    /// @notice Threshold filter passed to the offchain oracle rate query.
    uint256 public constant THRESHOLD = 90;

    /// @notice Converts token price in base units to USD using the offchain oracle rate.
    /// @param aggregator Offchain oracle used for token -> base conversion.
    /// @param token Token to convert.
    /// @param base Base token used by the oracle.
    /// @param baseUsd Base/USD price scaled to 1e18.
    /// @return USD price scaled to 1e18.
    function usdFromBase(address aggregator, address token, address base, uint256 baseUsd)
        internal
        view
        returns (uint256)
    {
        return IOffchainOracleAggregator(aggregator).getRateWithThreshold(IERC20(token), IERC20(base), true, THRESHOLD)
            .mulDiv(10 ** decimals(token), 10 ** decimals(base)).mulDiv(baseUsd, 1e18);
    }

    /// @notice Returns token decimals, defaulting to 18 if missing or token is native.
    /// @return Token decimals.
    function decimals(address token) internal view returns (uint8) {
        if (token == address(0)) return 18;
        try IERC20Metadata(token).decimals() returns (uint8 d) {
            return d;
        } catch {
            return 18;
        }
    }
}

/// @notice Offchain oracle interface used by the view-only USD oracles.
interface IOffchainOracleAggregator {
    function getRateWithThreshold(IERC20 srcToken, IERC20 dstToken, bool useWrappers, uint256 thresholdFilter)
        external
        view
        returns (uint256 weightedRate);
}
