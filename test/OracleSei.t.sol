// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "../contracts/OracleSei.sol";

contract OracleSeiTest is Test {
    OracleSei public oracleSei;

    address public oracle;
    address constant ORACLE_PRECOMPILE_ADDR = 0x0000000000000000000000000000000000001008;

    address constant USDC = 0xe15fC38F6D8c56aF07bbCBe3BAf5708A2Bf42392;
    address constant USDT = 0xB75D0B03c06A926e488e2659DF1A861F860bD3d1;
    address constant WETH = 0x160345fC359604fC6e70E3c5fAcbdE5F7A9342d8;
    address constant WBTC = 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c;
    address constant DRAGON = 0x0a526e425809aEA71eb279d24ae22Dee6C92A4Fe;
    address constant SEI = address(0);
    address constant WSEI = 0xE30feDd158A2e3b13e9badaeABaFc5516e95e8C7;
    uint256 constant THRESHOLD = 90;

    function setUp() public {
        string memory rpcUrl = vm.envOr("RPC_URL", string("https://evm-rpc.sei-apis.com"));
        vm.createSelectFork(rpcUrl);

        // Foundry (revm) doesn't implement Sei's custom oracle precompile at 0x1008. We "bridge" it by
        // etching a tiny contract at that address that proxies `getExchangeRates()` via `vm.rpc(eth_call)`
        // against the fork RPC. This uses the real on-chain precompile output (no mocked rates).
        vm.etch(ORACLE_PRECOMPILE_ADDR, address(new SeiOraclePrecompileRpc()).code);
        vm.allowCheatcodes(ORACLE_PRECOMPILE_ADDR);

        // Only map the base token (USDC) to force `usd(token)` to go through the offchain oracle path for other tokens.
        address[] memory tokens = new address[](1);
        string[] memory denoms = new string[](1);
        tokens[0] = USDC;
        denoms[0] = "uusdc";

        oracle = vm.envOr("ORACLE", address(0));
        if (oracle == address(0)) {
            string memory json = vm.readFile("script/config.json");
            string memory key = string.concat(".", vm.toString(block.chainid), ".oracle");
            oracle = vm.parseJsonAddress(json, key);
        }

        oracleSei = new OracleSei(oracle, THRESHOLD, tokens, denoms);
    }

    function testParse1e18_basic() public view {
        uint256 parsed = oracleSei.parse1e18("1234.23456789");
        assertEq(parsed, 1234_234_567_890_000_000_000); // 1234.23456789 * 1e18
    }

    function testParse1e18_truncatesLongFraction() public view {
        uint256 parsed = oracleSei.parse1e18("1234.1234567890123456789");
        assertEq(parsed, 1234_123_456_789_012_345_678); // truncates to 18 decimal places
    }

    function testParse1e18_noDecimalPoint() public view {
        uint256 parsed = oracleSei.parse1e18("42");
        assertEq(parsed, 42 * 1e18);
    }

    function testUsd_usdc_isSane() public view {
        // E2E: `usd(USDC)` should resolve via Sei oracle precompile through `usdFromPrecompile(base)`.
        uint256 usdcUsd = oracleSei.usd(USDC);
        assertGt(usdcUsd, 0.5e18);
        assertLt(usdcUsd, 2e18);
    }

    function testUsd_weth_usesOffchainOracleToBase_e2e() public view {
        // E2E: `usd(WETH)` should go through the offchain oracle to USDC (base), then convert with `usd(USDC)`.
        uint256 wethUsd = oracleSei.usd(WETH);
        assertGt(wethUsd, 100e18);
        assertLt(wethUsd, 100_000e18);
    }

    function testUsd_wbtc_usesOffchainOracleToBase_e2e() public view {
        uint256 wbtcUsd = oracleSei.usd(WBTC);
        assertGt(wbtcUsd, 1_000e18);
        assertLt(wbtcUsd, 1_000_000e18);
    }

    function testUsd_sei_usesOffchainOracleToBase_e2e() public view {
        uint256 seiUsd = oracleSei.usd(SEI);
        assertGt(seiUsd, 0);
        assertLt(seiUsd, 100e18);
    }

    function testUsd_wsei_usesOffchainOracleToBase_e2e() public view {
        uint256 wseiUsd = oracleSei.usd(WSEI);
        assertGt(wseiUsd, 0);
        assertLt(wseiUsd, 100e18);
    }

    function testUsd_usdt_usesOffchainOracleToBase_e2e() public view {
        uint256 usdtUsd = oracleSei.usd(USDT);
        assertGt(usdtUsd, 0.5e18);
        assertLt(usdtUsd, 2e18);
    }

    function testUsd_dragon_isInExpectedRange_e2e() public view {
        uint256 dragonUsd = oracleSei.usd(DRAGON);
        assertGt(dragonUsd, 0.001e18);
        assertLt(dragonUsd, 1e18);
    }
}

contract SeiOraclePrecompileRpc is IOraclePrecompile {
    // solhint-disable-next-line const-name-snakecase
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    bytes4 constant RPC_SELECTOR = bytes4(keccak256("rpc(string,string)"));

    function getExchangeRates() external view override returns (DenomOracleExchangeRatePair[] memory rates) {
        bytes memory callData = abi.encodeWithSelector(IOraclePrecompile.getExchangeRates.selector);
        string memory params =
            string.concat('[{"to":"', vm.toString(address(this)), '","data":"', vm.toString(callData), '"},"latest"]');

        bytes memory resp = _rpc("eth_call", params);
        bytes memory raw;
        if (resp.length > 0 && resp[0] == bytes1("{")) {
            raw = vm.parseJsonBytes(string(resp), ".result");
        } else if (resp.length > 1 && resp[0] == bytes1("0") && resp[1] == bytes1("x")) {
            raw = vm.parseBytes(string(resp));
        } else {
            raw = resp;
        }

        rates = abi.decode(raw, (DenomOracleExchangeRatePair[]));
    }

    function _rpc(string memory method, string memory params) internal view returns (bytes memory data) {
        (bool ok, bytes memory ret) = address(vm).staticcall(abi.encodeWithSelector(RPC_SELECTOR, method, params));
        require(ok, "vm.rpc failed");
        return abi.decode(ret, (bytes));
    }
}
