// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {ERC4626Test} from "../std-test/ERC4626.test.sol";
import {PoolMock} from "../aave-v3/mocks/PoolMock.sol";
import {RewardsControllerMock} from "../aave-v3/mocks/RewardsControllerMock.sol";
import {IPool} from "../../aave-v3/external/IPool.sol";
import {AaveV3ERC4626} from "../../aave-v3/AaveV3ERC4626.sol";
import {AaveV3ERC4626Factory} from "../../aave-v3/AaveV3ERC4626Factory.sol";
import {IRewardsController} from "../../aave-v3/external/IRewardsController.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {ERC4626Proxy, ERC4626} from "../../base/ERC4626Proxy.sol";

contract ERC4626ProxyTest is ERC4626Test {
    address public constant rewardRecipient = address(0x01);

    // copied from AaveV3ERC4626.t.sol
    ERC20Mock public aave;
    ERC20Mock public aToken;
    MyProxy public vault;
    ERC20Mock public underlying;
    PoolMock public lendingPool;
    ERC4626 public underlyingVault;
    IRewardsController public rewardsController;
    address public owner;

    function setUp() public override {
        // copied from AaveV3ERC4626.t.sol
        aave = new ERC20Mock();
        aToken = new ERC20Mock();
        underlying = new ERC20Mock();
        lendingPool = new PoolMock();
        rewardsController = new RewardsControllerMock(address(aave));
        AaveV3ERC4626Factory factory = new AaveV3ERC4626Factory(lendingPool, rewardRecipient, rewardsController);
        lendingPool.setReserveAToken(address(underlying), address(aToken));
        underlyingVault = AaveV3ERC4626(address(factory.createERC4626(underlying)));
        vault = new MyProxy(underlyingVault);

        // for ERC4626Test setup
        _underlying_ = address(underlying);
        _vault_ = address(vault);
        _delta_ = 0;
    }

    // custom setup for yield
    function setUpYield(Init memory init) public override {
        // setup initial yield
        if (init.yield >= 0) {
            uint gain = uint(init.yield);
            try underlying.mint(address(lendingPool), gain) {} catch { vm.assume(false); }
            try aToken.mint(address(vault), gain) {} catch { vm.assume(false); }
        } else {
            vm.assume(false); // TODO: test negative yield scenario
        }
    }

    function afterTest() public override {
      // Make sure that the supply matches the balance
      assertEq(vault.totalSupply(), underlyingVault.balanceOf(address(vault)));
    }

    // NOTE: The following tests are relaxed to consider only smaller values (of type uint120),
    // since the totalAssets(), maxWithdraw(), and maxRedeem() functions fail with large values (due to overflow).

    function test_totalAssets(Init memory init) public override {
        init = clamp(init, type(uint120).max);
        super.test_totalAssets(init);
    }

    function test_maxWithdraw(Init memory init) public override {
        init = clamp(init, type(uint120).max);
        super.test_maxWithdraw(init);
    }

    function test_maxRedeem(Init memory init) public override {
        init = clamp(init, type(uint120).max);
        super.test_maxRedeem(init);
    }

    function clamp(Init memory init, uint max) internal pure returns (Init memory) {
        for (uint i = 0; i < N; i++) {
            init.share[i] = init.share[i] % max;
            init.asset[i] = init.asset[i] % max;
        }
        init.yield = init.yield % int(max);
        return init;
    }
}

contract MyProxy is ERC4626Proxy {
  constructor(ERC4626 underlyingVault_) ERC4626Proxy(underlyingVault_) {}
}