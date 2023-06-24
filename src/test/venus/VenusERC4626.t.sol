// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {VenusERC4626} from "../../venus/VenusERC4626.sol";
import {IVComptroller} from "../../venus/external/IVComptroller.sol";
import {VenusERC4626Factory} from "../../venus/VenusERC4626Factory.sol";

contract VenusERC4626Test is Test {
    uint256 public fork;
    string RPC_URL_BNB = vm.envString("RPC_URL_BNB");
    address constant rewardRecipient = address(0x01);

    ERC20 constant underlying = busd;
    IVComptroller constant comptroller = IVComptroller(0xfD36E2c2a6789Db23113685031d7F16329158384);
    ERC20 constant busd = ERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address constant vBUSDAddress = 0x95c78222B3D6e262426483D42CfA53685A67Ab9D;
    address constant vBNBAddress = 0xA07c5b74C9B40447a954e1466938b865b6BBea36;

    VenusERC4626 public vault;
    VenusERC4626Factory public factory;

    function setUp() public {
        fork = vm.createFork(RPC_URL_BNB);
        vm.selectFork(fork);
        factory = new VenusERC4626Factory(comptroller, vBNBAddress, rewardRecipient);
        vault = VenusERC4626(address(factory.createERC4626(busd)));

        vm.label(address(busd), "BUSD");
        vm.label(vBUSDAddress, "cBUSD");
        vm.label(address(comptroller), "Comptroller");
        vm.label(address(0xABCD), "Alice");
        vm.label(address(0xDCBA), "Bob");
    }

    function testFailDepositWithNotEnoughApproval() public {
        deal(address(underlying), address(this), 0.5e18);
        underlying.approve(address(vault), 0.5e18);
        assertEq(underlying.allowance(address(this), address(vault)), 0.5e18);

        vault.deposit(1e18, address(this));
    }

    function testFailWithdrawWithNotEnoughUnderlyingAmount() public {
        deal(address(underlying), address(this), 0.5e18);
        underlying.approve(address(vault), 0.5e18);

        vault.deposit(0.5e18, address(this));

        vault.withdraw(1e18, address(this), address(this));
    }

    function testFailRedeemWithNotEnoughShareAmount() public {
        deal(address(underlying), address(this), 0.5e18);
        underlying.approve(address(vault), 0.5e18);

        vault.deposit(0.5e18, address(this));

        vault.redeem(1e18, address(this), address(this));
    }

    function testFailWithdrawWithNoUnderlyingAmount() public {
        vault.withdraw(1e18, address(this), address(this));
    }

    function testFailRedeemWithNoShareAmount() public {
        vault.redeem(1e18, address(this), address(this));
    }

    function testFailDepositWithNoApproval() public {
        vault.deposit(1e18, address(this));
    }

    function testFailMintWithNoApproval() public {
        vault.mint(1e18, address(this));
    }

    function testFailDepositZero() public {
        vault.deposit(0, address(this));
    }

    function testMintZero() public {
        vault.mint(0, address(this));

        assertEq(vault.balanceOf(address(this)), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(address(this))), 0);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.totalAssets(), 0);
    }

    function testFailRedeemZero() public {
        vault.redeem(0, address(this), address(this));
    }

    function testWithdrawZero() public {
        vault.withdraw(0, address(this), address(this));

        assertEq(vault.balanceOf(address(this)), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(address(this))), 0);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.totalAssets(), 0);
    }

    function test_claimRewards() public {
        vault.claimRewards();
    }
}
