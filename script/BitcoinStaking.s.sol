// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BitcoinStaking} from "src/BitcoinStaking.sol";
import {Script, console2} from "forge-std/Script.sol";

contract BitcoinStakingScript is Script {
    function run() public returns (BitcoinStaking deployment) {
        vm.broadcast();
        deployment = new BitcoinStaking();
    }
}
