// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "../interfaces/IAlgebraPool.sol";
import "./UniswapV3LikeOracle.sol";

contract AlgebraCustomPoolOracle is UniswapV3LikeOracle {
    address public immutable POOL_DEPLOYER;
    address public immutable CUSTOM_DEPLOYER;

    constructor(address _poolDeployer, address _customDeployer, bytes32 _initcodeHash)
        UniswapV3LikeOracle(_poolDeployer, _initcodeHash, new uint24[](1))
    {
        POOL_DEPLOYER = _poolDeployer;
        CUSTOM_DEPLOYER = _customDeployer;
    }

    function _getPool(
        address token0,
        address token1,
        uint24 /* fee */
    )
        internal
        view
        override
        returns (address)
    {
        bytes32 salt;
        if (CUSTOM_DEPLOYER == address(0)) {
            salt = keccak256(abi.encode(token0, token1));
        } else {
            salt = keccak256(abi.encode(CUSTOM_DEPLOYER, token0, token1));
        }
        return address(uint160(uint256(keccak256(abi.encodePacked(hex"ff", POOL_DEPLOYER, salt, INITCODE_HASH)))));
    }

    function _currentState(address pool) internal view override returns (uint256 sqrtPriceX96, int24 tick) {
        (sqrtPriceX96, tick) = IAlgebraPool(pool).globalState();
    }
}
