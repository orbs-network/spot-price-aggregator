// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";

abstract contract RpcUtils is Test {
    function _rpcUrl(string memory chain) internal returns (string memory) {
        string[] memory cmd = new string[](3);
        cmd[0] = "getchain";
        cmd[1] = "-u";
        cmd[2] = chain;
        return vm.trim(string(vm.ffi(cmd)));
    }
}
