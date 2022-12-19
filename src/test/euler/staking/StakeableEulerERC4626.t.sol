// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {EulerMock} from "../mocks/EulerMock.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";
import {StakeableEulerERC4626} from "../../../euler/staking/StakeableEulerERC4626.sol";
import {EulerETokenMock} from "../mocks/EulerETokenMock.sol";
import {EulerMarketsMock} from "../mocks/EulerMarketsMock.sol";
import {EulerRewardsDistributionMock} from "../mocks/EulerRewardsDistribution.sol";

contract StakeableEulerERC4626Test is Test {
    EulerMock public euler;
    StakeableEulerERC4626 public vault;
    ERC20Mock public underlying;
    EulerETokenMock public eToken;
    EulerMarketsMock public markets;
    EulerRewardsDistributionMock public rewardsDistribution;
    address owner = address(0xABCD);

    function setUp() public {
        euler = new EulerMock();
        underlying = new ERC20Mock();
        eToken = new EulerETokenMock(underlying, euler);
        markets = new EulerMarketsMock();        

        markets.setETokenForUnderlying(address(underlying), address(eToken));

        rewardsDistribution = new EulerRewardsDistributionMock();

        vault = new StakeableEulerERC4626(underlying, address(euler), eToken, rewardsDistribution, owner);
    }

    function testInitialization() public {
        assertEq(address(vault.rewardsDistribution()), address(rewardsDistribution));
        assertEq(vault.owner(), owner);
    }

}
