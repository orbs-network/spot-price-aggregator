// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IOffchainOracleView {
    function getRateWithThreshold(IERC20 srcToken, IERC20 dstToken, bool useWrappers, uint256 thresholdFilter)
        external
        view
        returns (uint256 weightedRate);
}

interface IOraclePrecompile {
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

contract OracleSei {
    using Math for uint256;
    using Strings for string;

    error ArraysLengthMismatch();
    error PrecompileOracleNotFound();

    address public immutable oracle;
    address public immutable base;
    uint256 public immutable threshold;

    IOraclePrecompile public constant ORACLE_PRECOMPILE = IOraclePrecompile(0x0000000000000000000000000000000000001008);
    mapping(address => bytes32) public denomHash;

    constructor(address _oracle, uint256 _threshold, address[] memory tokens, string[] memory denoms) {
        oracle = _oracle;
        threshold = _threshold;

        unchecked {
            if (tokens.length == 0 || tokens.length != denoms.length) revert ArraysLengthMismatch();
            base = tokens[0];
            for (uint256 i; i < tokens.length; i++) {
                denomHash[tokens[i]] = keccak256(bytes(denoms[i]));
            }
        }
    }

    function usd(address token) public view returns (uint256) {
        if (denomHash[token] != bytes32(0)) return usdFromPrecompile(token);
        uint256 rateToBase =
            IOffchainOracleView(oracle).getRateWithThreshold(IERC20(token), IERC20(base), true, threshold);

        uint256 baseUnitsPerToken = rateToBase.mulDiv(10 ** _decimals(token), 10 ** _decimals(base));
        return baseUnitsPerToken.mulDiv(usdFromPrecompile(base), 1e18);
    }

    function usdFromPrecompile(address token) public view returns (uint256) {
        bytes32 target = denomHash[token];
        if (target == bytes32(0)) revert PrecompileOracleNotFound();
        IOraclePrecompile.DenomOracleExchangeRatePair[] memory rates = ORACLE_PRECOMPILE.getExchangeRates();
        for (uint256 i; i < rates.length; i++) {
            if (keccak256(bytes(rates[i].denom)) == target) {
                return parse1e18(rates[i].oracleExchangeRateVal.exchangeRate);
            }
        }
        revert PrecompileOracleNotFound();
    }

    function parse1e18(string memory rate) public pure returns (uint256) {
        bytes memory b = bytes(rate);
        uint256 dot = b.length;
        for (uint256 i; i < b.length; i++) {
            if (b[i] == bytes1(".")) {
                dot = i;
                break;
            }
        }

        uint256 intPart = rate.parseUint(0, dot);
        if (dot == b.length) return intPart * 1e18;

        uint256 fracStart = dot + 1;
        uint256 fracLen = (b.length - fracStart).min(18);
        if (fracLen == 0) return intPart * 1e18;
        uint256 frac = rate.parseUint(fracStart, fracStart + fracLen);
        if (fracLen < 18) frac *= 10 ** (18 - fracLen);

        return intPart * 1e18 + frac;
    }

    function _decimals(address token) private view returns (uint8) {
        if (token == address(0)) return 18;
        try IERC20Metadata(token).decimals() returns (uint8 d) {
            return d;
        } catch {
            return 18;
        }
    }
}
