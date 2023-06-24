// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {IVERC20} from "../../venus/external/IVERC20.sol";
import {VenusERC4626} from "../../venus/VenusERC4626.sol";
import {IVComptroller} from "../../venus/external/IVComptroller.sol";
import {VenusERC4626Factory} from "../../venus/VenusERC4626Factory.sol";

contract VenusERC4626FactoryTest is Test {
    uint256 public fork;
    string RPC_URL_BNB = vm.envString("RPC_URL_BNB");
    address constant rewardRecipient = address(0x01);

    IVComptroller constant comptroller = IVComptroller(0xfD36E2c2a6789Db23113685031d7F16329158384);
    ERC20 constant busd = ERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address constant vBUSDAddress = 0x95c78222B3D6e262426483D42CfA53685A67Ab9D;
    address constant vBNBAddress = 0xA07c5b74C9B40447a954e1466938b865b6BBea36;

    VenusERC4626Factory public factory;

    function setUp() public {
        fork = vm.createFork(RPC_URL_BNB);
        vm.selectFork(fork);
        factory = new VenusERC4626Factory(comptroller, vBNBAddress, rewardRecipient);
    }

    function test_createERC4626() public {
        VenusERC4626 vault = VenusERC4626(address(factory.createERC4626(busd)));

        assertEq(address(vault.comp()), address(comptroller.getXVSAddress()), "comp incorrect");
        assertEq(address(vault.cToken()), vBUSDAddress, "cToken incorrect");
        assertEq(address(vault.rewardRecipient()), rewardRecipient, "rewardRecipient incorrect");
        assertEq(address(vault.comptroller()), address(comptroller), "comptroller incorrect");
    }

    function test_computeERC4626Address() public {
        VenusERC4626 vault = VenusERC4626(address(factory.createERC4626(busd)));

        assertEq(address(factory.computeERC4626Address(busd)), address(vault), "computed vault address incorrect");
    }

    function test_fail_createERC4626ForAssetWithoutEToken() public {
        ERC20Mock fakeAsset = new ERC20Mock();
        vm.expectRevert(abi.encodeWithSignature("VenusERC4626Factory__CTokenNonexistent()"));
        factory.createERC4626(fakeAsset);
    }
}
