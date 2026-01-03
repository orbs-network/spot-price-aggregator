// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {BaseCoinWrapper} from "contracts/wrappers/BaseCoinWrapper.sol";
import {IOracle} from "contracts/interfaces/IOracle.sol";
import {IWrapper} from "contracts/interfaces/IWrapper.sol";
import {AlgebraOracle} from "contracts/oracles/AlgebraOracle.sol";
import {SolidlyOracleNoCreate2} from "contracts/oracles/SolidlyOracleNoCreate2.sol";

contract OffchainOracleAvaxTest is Test {
    IERC20 private constant NONE = IERC20(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
    IERC20 private constant NATIVE = IERC20(address(0));

    address private constant WETH = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address private constant TOKEN_FBOMB = 0x5C09A9cE08C4B332Ef1CC5f7caDB1158C32767Ce;

    // Wrappers (from config)
    address private constant WRAPPER_AAVE_V2 = 0x8Aa57827C3D147E39F1058517939461538D9C56A;
    address private constant WRAPPER_AAVE_V3 = 0x0c8fc7a71C28c768FDC1f7d75835229beBEB1573;
    address private constant WRAPPER_STATA = 0x1A75DF59f464a70Cc8f7383983852FF72e5F5167;

    // Existing adapter deployments (from config)
    address private constant ORACLE_JOE = 0xc197Ab9d47206dAf739a47AC75D0833fD2b0f87F;
    address private constant ORACLE_PANGOLIN = 0xE93293A6088d3a8abDDf62e6CA1A085Cec97D06F;
    address private constant ORACLE_SUSHI = 0x2A45d538f460DDBEeA3a899b0674dA3DFE318faa;
    address private constant ORACLE_UNISWAP_V2 = 0x4C5B9573dE7660c097F1a21050038378CD691066;
    address private constant ORACLE_UNISWAP_V3 = 0x008D10214049593C6e63564946FFb64A6F706732;
    address private constant ORACLE_UNISWAP_V4 = 0xFbF54317e4820B461E7fA1B2819B6755e1cc0F62;
    address private constant ORACLE_CURVE = 0x4e5Cee3B8Af0CB46EFAA94Cba5E0f25f8770BB19;

    // Blackhole factories (from config)
    address private constant BLACKHOLE_AMM_FACTORY = 0xfE926062Fb99CA5653080d6C14fE945Ad68c265C;

    address private constant BLACKHOLE_CL1_FACTORY = 0xDcFccf2e8c4EfBba9127B80eAc76c5A122125d29;
    address private constant BLACKHOLE_CL50_FACTORY = 0x58b05074D52D1a84D8FfDAddA3c1b652e8C56994;
    address private constant BLACKHOLE_CL100_FACTORY = 0xf9221dE143A0E57c324bF2a0f281e605e845D767;
    address private constant BLACKHOLE_CL200_FACTORY = 0x5D433A94A4a2aA8f9AA34D8D15692Dc2E9960584;
    bytes32 private constant BLACKHOLE_CL_INITCODEHASH =
        0xeaa3eea3233916c82fe1281a51bd9cde844b7c4673c0714ca0028a57f5634752;

    OffchainOracle private aggregator;

    function setUp() public {
        vm.createSelectFork(vm.envString("FOUNDRY_ETH_RPC_URL"));
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

        // Build connectors: NONE, NATIVE, WETH, then config connectors
        address[] memory extraConnectors = new address[](5);
        extraConnectors[0] = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;
        extraConnectors[1] = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
        extraConnectors[2] = 0x50b7545627a5162F82A992c33b87aDc75187B218;
        extraConnectors[3] = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
        extraConnectors[4] = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

        IERC20[] memory connectors = new IERC20[](extraConnectors.length + 3);
        connectors[0] = NONE;
        connectors[1] = NATIVE;
        connectors[2] = IERC20(WETH);
        for (uint256 i = 0; i < extraConnectors.length; i++) {
            connectors[i + 3] = IERC20(extraConnectors[i]);
        }

        BaseCoinWrapper baseCoinWrapper = new BaseCoinWrapper(NATIVE, IERC20(WETH));
        IWrapper[] memory initialWrappers = new IWrapper[](1);
        initialWrappers[0] = baseCoinWrapper;
        MultiWrapper multiWrapper = new MultiWrapper(initialWrappers, owner);

        IOracle[] memory emptyOracles = new IOracle[](0);
        OffchainOracle.OracleType[] memory emptyTypes = new OffchainOracle.OracleType[](0);
        aggregator = new OffchainOracle(multiWrapper, emptyOracles, emptyTypes, connectors, IERC20(WETH), owner);

        // Add wrappers
        multiWrapper.addWrapper(IWrapper(WRAPPER_AAVE_V2));
        multiWrapper.addWrapper(IWrapper(WRAPPER_AAVE_V3));
        multiWrapper.addWrapper(IWrapper(WRAPPER_STATA));

        // Add existing oracle deployments
        aggregator.addOracle(IOracle(ORACLE_JOE), OffchainOracle.OracleType(0));
        aggregator.addOracle(IOracle(ORACLE_PANGOLIN), OffchainOracle.OracleType(0));
        aggregator.addOracle(IOracle(ORACLE_SUSHI), OffchainOracle.OracleType(0));
        aggregator.addOracle(IOracle(ORACLE_UNISWAP_V2), OffchainOracle.OracleType(0));
        aggregator.addOracle(IOracle(ORACLE_UNISWAP_V3), OffchainOracle.OracleType(0));
        aggregator.addOracle(IOracle(ORACLE_UNISWAP_V4), OffchainOracle.OracleType(0));
        aggregator.addOracle(IOracle(ORACLE_CURVE), OffchainOracle.OracleType(0));

        // Deploy and add Blackhole adapters
        SolidlyOracleNoCreate2 solidly = new SolidlyOracleNoCreate2(BLACKHOLE_AMM_FACTORY);
        aggregator.addOracle(solidly, OffchainOracle.OracleType(0));

        AlgebraOracle cl1 = new AlgebraOracle(BLACKHOLE_CL1_FACTORY, BLACKHOLE_CL_INITCODEHASH);
        AlgebraOracle cl50 = new AlgebraOracle(BLACKHOLE_CL50_FACTORY, BLACKHOLE_CL_INITCODEHASH);
        AlgebraOracle cl100 = new AlgebraOracle(BLACKHOLE_CL100_FACTORY, BLACKHOLE_CL_INITCODEHASH);
        AlgebraOracle cl200 = new AlgebraOracle(BLACKHOLE_CL200_FACTORY, BLACKHOLE_CL_INITCODEHASH);

        aggregator.addOracle(cl1, OffchainOracle.OracleType(0));
        aggregator.addOracle(cl50, OffchainOracle.OracleType(0));
        aggregator.addOracle(cl100, OffchainOracle.OracleType(0));
        aggregator.addOracle(cl200, OffchainOracle.OracleType(0));
    }
}
