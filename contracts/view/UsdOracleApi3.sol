// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {UsdOracleCore} from "./UsdOracleCore.sol";

/// @notice View-only USD oracle (1e18) using API3 reader proxies or offchain conversion to a base token.
/// @dev Pricing flow: (1) direct API3 proxy when configured; otherwise (2) token -> base via OffchainOracle;
/// @dev then (3) base -> USD via the base API3 proxy.
/// @dev Intended for off-chain reads; not suitable for on-chain pricing.
contract UsdOracleApi3 is UsdOracleCore {
    using SafeCast for int256;

    error ArraysLengthMismatch();
    error MissingFeed(address token);

    mapping(address => address) public api3Feed;

    /// @param _aggregator Offchain oracle used for token -> base conversion.
    /// @param tokens Token list; tokens[0] is the base token.
    /// @param feeds API3 reader proxy addresses, aligned 1:1 with tokens.
    constructor(address _aggregator, address[] memory tokens, address[] memory feeds)
        UsdOracleCore(_aggregator, tokens[0])
    {
        if (tokens.length == 0 || tokens.length != feeds.length) revert ArraysLengthMismatch();
        for (uint256 i; i < tokens.length; i++) {
            api3Feed[tokens[i]] = feeds[i];
        }
    }

    function _hasDirect(address token) internal view override returns (bool) {
        return api3Feed[token] != address(0);
    }

    function _directUsd(address token) internal view override returns (uint256 price, uint256 updated) {
        address feed = api3Feed[token];
        if (feed == address(0)) revert MissingFeed(token);

        (int224 value, uint32 timestamp) = IApi3ReaderProxy(feed).read();
        updated = timestamp;
        price = int256(value).toUint256();
    }
}

/// @notice Minimal API3 reader proxy interface needed by this oracle.
interface IApi3ReaderProxy {
    function read() external view returns (int224 value, uint32 timestamp);
}
