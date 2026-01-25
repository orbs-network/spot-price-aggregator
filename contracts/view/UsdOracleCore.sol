// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {AggregatorLib} from "./AggregatorLib.sol";

/// @notice Shared view-only USD oracle logic.
abstract contract UsdOracleCore {
    struct Quote {
        uint256 price;
        uint8 decimals;
    }

    error StaleAnswer(address token);
    error ZeroPrice(address token);

    uint256 public constant TTL = 1 days;

    address public immutable aggregator;
    address public immutable base;

    constructor(address _aggregator, address _base) {
        aggregator = _aggregator;
        base = _base;
    }

    /// @notice Returns token/USD price scaled to 1e18.
    /// @param token Token to price.
    /// @return price USD price scaled to 1e18.
    /// @return decimals Token decimals (or 18 if unavailable).
    function usd(address token) public view returns (uint256 price, uint8 decimals) {
        decimals = AggregatorLib.decimals(token);
        if (_hasDirect(token)) return (_freshDirectUsd(token), decimals);

        price = AggregatorLib.usdFromBase(aggregator, token, base, _freshDirectUsd(base));
    }

    /// @notice Returns token/USD prices scaled to 1e18.
    /// @param tokens Tokens to price.
    /// @return quotes Array of (price, decimals) tuples for each token.
    function usd(address[] memory tokens) public view returns (Quote[] memory quotes) {
        quotes = new Quote[](tokens.length);
        uint256 baseUsd;

        for (uint256 i; i < tokens.length; i++) {
            quotes[i].decimals = AggregatorLib.decimals(tokens[i]);

            if (_hasDirect(tokens[i])) {
                quotes[i].price = _freshDirectUsd(tokens[i]);
            } else {
                if (baseUsd == 0) baseUsd = _freshDirectUsd(base);
                quotes[i].price = AggregatorLib.usdFromBase(aggregator, tokens[i], base, baseUsd);
            }
        }
    }

    function _freshDirectUsd(address token) private view returns (uint256) {
        (uint256 price, uint256 updated) = _directUsd(token);
        if (block.timestamp >= updated + TTL) revert StaleAnswer(token);
        if (price == 0) revert ZeroPrice(token);
        return price;
    }

    function _hasDirect(address token) internal view virtual returns (bool);
    function _directUsd(address token) internal view virtual returns (uint256 price, uint256 updated);
}
