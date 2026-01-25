// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ParseLib} from "./ParseLib.sol";
import {UsdOracleCore} from "./UsdOracleCore.sol";

/// @notice View-only USD oracle (1e18) for Sei using the Sei precompile or offchain conversion to a base token.
/// @dev Pricing flow: (1) Sei precompile when denom is configured; otherwise (2) token -> base via
/// @dev OffchainOracle; then (3) base -> USD via the precompile.
/// @dev Intended for off-chain reads; not suitable for on-chain pricing.
contract UsdOracleSei is UsdOracleCore {
    using SafeCast for int256;

    error ArraysLengthMismatch();
    error MissingPrecompile(address token);

    ISeiPrecompile public constant SEI_PRECOMPILE = ISeiPrecompile(0x0000000000000000000000000000000000001008);

    mapping(address => bytes32) public denomHash;

    /// @param _aggregator Offchain oracle used for token -> base conversion.
    /// @param tokens Token list; tokens[0] is the base token.
    /// @param denoms Sei denom strings aligned 1:1 with tokens.
    constructor(address _aggregator, address[] memory tokens, string[] memory denoms)
        UsdOracleCore(_aggregator, tokens[0])
    {
        if (tokens.length == 0 || tokens.length != denoms.length) revert ArraysLengthMismatch();
        for (uint256 i; i < tokens.length; i++) {
            denomHash[tokens[i]] = keccak256(bytes(denoms[i]));
        }
    }

    function _hasDirect(address token) internal view override returns (bool) {
        return denomHash[token] != bytes32(0);
    }

    function _directUsd(address token) internal view override returns (uint256 price, uint256 updated) {
        bytes32 target = denomHash[token];
        if (target == bytes32(0)) revert MissingPrecompile(token);

        ISeiPrecompile.DenomOracleExchangeRatePair[] memory rates = SEI_PRECOMPILE.getExchangeRates();
        for (uint256 i; i < rates.length; i++) {
            if (keccak256(bytes(rates[i].denom)) == target) {
                updated = int256(rates[i].oracleExchangeRateVal.lastUpdateTimestamp).toUint256();
                price = ParseLib.parse1e18(rates[i].oracleExchangeRateVal.exchangeRate);
                return (price, updated);
            }
        }
        revert MissingPrecompile(token);
    }
}

/// @notice Minimal Sei precompile interface needed by this oracle.
interface ISeiPrecompile {
    struct OracleExchangeRate {
        string exchangeRate;
        string lastUpdate;
        int64 lastUpdateTimestamp;
    }

    struct DenomOracleExchangeRatePair {
        string denom;
        OracleExchangeRate oracleExchangeRateVal;
    }

    function getExchangeRates() external view returns (DenomOracleExchangeRatePair[] memory rates);
}
