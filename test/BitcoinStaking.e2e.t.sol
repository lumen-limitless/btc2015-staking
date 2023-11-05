// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {BitcoinStaking} from "../src/BitcoinStaking.sol";
import {ERC20} from "ERC4626-revenue-distribution-token/ERC20.sol";
import "forge-std/Test.sol";

contract BitcoinStakingE2ETests is Test {
    BitcoinStaking public bitcoinStaking;
    address public constant deployer = address(0xC7A7a14055c433399b89f2A3C70e3CaB70E97dEd);
    address public constant owner = address(0xC701E3D2DcCf4115D87a92f2a6E0eeEF2f0D0F25);
    ERC20 public constant asset = ERC20(address(0x476908D9f75687684CE3DBF6990e722129cDbCc6));
    address public immutable user1 = vm.addr(1);
    address public immutable user2 = vm.addr(2);
    address public immutable user3 = vm.addr(3);

    uint256 public constant PERIOD = 1460 days;

    uint256 public constant START = 10_000;

    function setUp() public {
        vm.createSelectFork(vm.envString("RPC_URL_MAINNET"));

        vm.startPrank(deployer);
        bitcoinStaking = new BitcoinStaking();
        vm.stopPrank();

        //deal tokens to users and staking contract
        deal(address(asset), owner, 1000e8);
        deal(address(asset), user1, 1000e8);
        deal(address(asset), user2, 1000e8);
        deal(address(asset), user3, 1000e8);
        deal(address(asset), address(bitcoinStaking), 1000e8);

        vm.warp(START);
    }

    function test_e2e() public {
        assertEq(bitcoinStaking.owner(), owner);
        assertEq(bitcoinStaking.asset(), address(asset));
        assertEq(bitcoinStaking.totalSupply(), 0);
        assertEq(bitcoinStaking.totalAssets(), 0);

        //owner do initial deposit and begin staking
        vm.startPrank(owner);
        asset.approve(address(bitcoinStaking), 1000e8);
        bitcoinStaking.deposit(1000e8, owner);
        bitcoinStaking.updateVestingSchedule(PERIOD);
        vm.stopPrank();

        assertEq(bitcoinStaking.totalSupply(), 1000e8);
        assertEq(bitcoinStaking.totalAssets(), 1000e8);
        assertEq(bitcoinStaking.vestingPeriodFinish(), START + PERIOD);

        //user1 do deposit
        vm.startPrank(user1);
        asset.approve(address(bitcoinStaking), 1000e8);
        bitcoinStaking.deposit(1000e8, user1);
        vm.stopPrank();

        assertEq(bitcoinStaking.totalSupply(), 2000e8);
        assertEq(bitcoinStaking.totalAssets(), 2000e8);

        vm.warp(START + PERIOD / 2);

        //check contract tracking rewards correctly
        assertEq(bitcoinStaking.totalSupply(), 2000e8);
        assertApproxEqAbsDecimal(bitcoinStaking.totalAssets(), 2000e8 + 1000e8 / 2, 1, 8);

        vm.warp(START + PERIOD + 1);

        //check contract tracking rewards correctly
        assertEq(bitcoinStaking.totalSupply(), 2000e8);
        assertApproxEqAbsDecimal(bitcoinStaking.totalAssets(), 3000e8, 1, 8);
    }
}
