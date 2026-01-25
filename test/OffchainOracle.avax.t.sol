// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {RpcUtils} from "test/utils/RpcUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {BaseCoinWrapper} from "contracts/wrappers/BaseCoinWrapper.sol";
import {IOracle} from "contracts/interfaces/IOracle.sol";
import {IWrapper} from "contracts/interfaces/IWrapper.sol";
import {AlgebraCustomPoolOracle} from "contracts/oracles/AlgebraCustomPoolOracle.sol";
import {SolidlyOracleNoCreate2} from "contracts/oracles/SolidlyOracleNoCreate2.sol";

contract OffchainOracleAvaxTest is RpcUtils {
    IERC20 private constant NONE = IERC20(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
    IERC20 private constant NATIVE = IERC20(address(0));

    address private constant WETH = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address private constant TOKEN_FBOMB = 0x5C09A9cE08C4B332Ef1CC5f7caDB1158C32767Ce;
    string private constant CONFIG_PATH = "script/input/config.json";
    string private constant CHAIN_KEY = ".43114";

    OffchainOracle private aggregator;

    function setUp() public {
        vm.createSelectFork(_rpcUrl("avax"));
        _deployFromConfig();
    }

    function test_fBomb_hasRateToEth_onLatestFork() public {
        uint256 rateThreshold10 = aggregator.getRateToEthWithThreshold(IERC20(TOKEN_FBOMB), true, 10);
        uint256 rateThreshold0 = aggregator.getRateToEthWithThreshold(IERC20(TOKEN_FBOMB), true, 0);

        emit log_named_uint("rateToEth_threshold10", rateThreshold10);
        emit log_named_uint("rateToEth_threshold0", rateThreshold0);

        assertGt(rateThreshold10, 0, "rateToEth=0 at threshold 10");
    }

    function _deployFromConfig() private {
        address owner = address(this);
        string memory json = vm.readFile(CONFIG_PATH);

        // Build connectors: NONE, NATIVE, WETH, then config connectors
        address[] memory extraConnectors = vm.parseJsonAddressArray(json, string.concat(CHAIN_KEY, ".connectors"));

        IERC20[] memory connectors = new IERC20[](extraConnectors.length + 3);
        connectors[0] = NONE;
        connectors[1] = NATIVE;
        connectors[2] = IERC20(WETH);
        for (uint256 i = 0; i < extraConnectors.length; i++) {
            connectors[i + 3] = IERC20(extraConnectors[i]);
        }

        // Existing adapter deployments (from config)
        address oracleJoe = vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[0].env.address"));
        address oraclePangolin = vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[1].env.address"));
        address oracleSushi = vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[2].env.address"));
        address oracleUniswapV2 = vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[3].env.address"));
        address oracleUniswapV3 = vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[4].env.address"));
        address oracleUniswapV4 = vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[5].env.address"));
        address oracleCurve = vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[6].env.address"));

        // Blackhole factories (from config)
        address blackholeAmmFactory = vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[7].env.factory"));
        address blackholeClPoolDeployer =
            vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[8].env.poolDeployer"));
        address blackholeCl1Deployer =
            vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[9].env.customDeployer"));
        address blackholeClDefaultDeployer =
            vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[8].env.customDeployer"));
        address blackholeCl50Deployer =
            vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[10].env.customDeployer"));
        address blackholeCl100Deployer =
            vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[11].env.customDeployer"));
        address blackholeCl200Deployer =
            vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[12].env.customDeployer"));
        bytes32 blackholeInitcodeHash =
            vm.parseJsonBytes32(json, string.concat(CHAIN_KEY, ".adapters[8].env.initcodehash"));

        BaseCoinWrapper baseCoinWrapper = new BaseCoinWrapper(NATIVE, IERC20(WETH));
        IWrapper[] memory initialWrappers = new IWrapper[](1);
        initialWrappers[0] = baseCoinWrapper;
        MultiWrapper multiWrapper = new MultiWrapper(initialWrappers, owner);

        IOracle[] memory emptyOracles = new IOracle[](0);
        OffchainOracle.OracleType[] memory emptyTypes = new OffchainOracle.OracleType[](0);
        aggregator = new OffchainOracle(multiWrapper, emptyOracles, emptyTypes, connectors, IERC20(WETH), owner);

        // Add existing oracle deployments
        aggregator.addOracle(IOracle(oracleJoe), OffchainOracle.OracleType(0));
        aggregator.addOracle(IOracle(oraclePangolin), OffchainOracle.OracleType(0));
        aggregator.addOracle(IOracle(oracleSushi), OffchainOracle.OracleType(0));
        aggregator.addOracle(IOracle(oracleUniswapV2), OffchainOracle.OracleType(0));
        aggregator.addOracle(IOracle(oracleUniswapV3), OffchainOracle.OracleType(0));
        aggregator.addOracle(IOracle(oracleUniswapV4), OffchainOracle.OracleType(0));
        aggregator.addOracle(IOracle(oracleCurve), OffchainOracle.OracleType(0));

        // Deploy and add Blackhole adapters
        SolidlyOracleNoCreate2 solidly = new SolidlyOracleNoCreate2(blackholeAmmFactory);
        aggregator.addOracle(solidly, OffchainOracle.OracleType(0));

        AlgebraCustomPoolOracle cl1 =
            new AlgebraCustomPoolOracle(blackholeClPoolDeployer, blackholeCl1Deployer, blackholeInitcodeHash);
        AlgebraCustomPoolOracle clDefault =
            new AlgebraCustomPoolOracle(blackholeClPoolDeployer, blackholeClDefaultDeployer, blackholeInitcodeHash);
        AlgebraCustomPoolOracle cl50 =
            new AlgebraCustomPoolOracle(blackholeClPoolDeployer, blackholeCl50Deployer, blackholeInitcodeHash);
        AlgebraCustomPoolOracle cl100 =
            new AlgebraCustomPoolOracle(blackholeClPoolDeployer, blackholeCl100Deployer, blackholeInitcodeHash);
        AlgebraCustomPoolOracle cl200 =
            new AlgebraCustomPoolOracle(blackholeClPoolDeployer, blackholeCl200Deployer, blackholeInitcodeHash);

        aggregator.addOracle(cl1, OffchainOracle.OracleType(0));
        aggregator.addOracle(clDefault, OffchainOracle.OracleType(0));
        aggregator.addOracle(cl50, OffchainOracle.OracleType(0));
        aggregator.addOracle(cl100, OffchainOracle.OracleType(0));
        aggregator.addOracle(cl200, OffchainOracle.OracleType(0));
    }
}
