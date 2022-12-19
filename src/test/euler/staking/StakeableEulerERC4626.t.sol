// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {EulerMock} from "../mocks/EulerMock.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";
import {StakeableEulerERC4626} from "../../../euler/staking/StakeableEulerERC4626.sol";
import {EulerETokenMock} from "../mocks/EulerETokenMock.sol";
import {EulerMarketsMock} from "../mocks/EulerMarketsMock.sol";
import {EulerRewardsDistributionMock} from "../mocks/EulerRewardsDistributionMock.sol";
import {EulerStakingRewardsMock} from "../mocks/EulerStakingRewardsMock.sol";
import {IRewardsDistribution} from "../../../euler/external/IRewardsDistribution.sol";

contract StakeableEulerERC4626Test is Test {
    EulerMock public euler;
    StakeableEulerERC4626 public vault;
    ERC20Mock public underlying;
    ERC20Mock public rewardsToken;
    EulerStakingRewardsMock public stakingRewards;
    EulerETokenMock public eToken;
    EulerMarketsMock public markets;
    EulerRewardsDistributionMock public rewardsDistribution;
    address owner = address(0xABCD);
    address recipient = address(0xDEAD);

    function setUp() public {
        euler = new EulerMock();
        underlying = new ERC20Mock();
        eToken = new EulerETokenMock(underlying, euler);
        markets = new EulerMarketsMock();        

        markets.setETokenForUnderlying(address(underlying), address(eToken));

        rewardsDistribution = new EulerRewardsDistributionMock();

        vault = new StakeableEulerERC4626(underlying, address(euler), eToken, rewardsDistribution, owner);

        stakingRewards = new EulerStakingRewardsMock(address(rewardsToken), address(eToken));
        _setDistribution(1, stakingRewards);
    }

    function testInitialization() public {
        assertEq(address(vault.rewardsDistribution()), address(rewardsDistribution));
        assertEq(vault.owner(), owner);
    }

    function testFailNotOwner() public {
        vault.updateStakingAddress(1, recipient);
    }

    function testFailInvalidIndex() public {
        vm.prank(owner);
        vault.updateStakingAddress(2, recipient);
    }

    function testFailWrongToken() public {
        EulerStakingRewardsMock stakingRewards_ = new EulerStakingRewardsMock(address(rewardsToken), address(0x0101));
        _setDistribution(2, stakingRewards_);

        vm.prank(owner);
        vault.updateStakingAddress(2, recipient);
    }

    function testAddNewStakingAddress() public {       
        vm.prank(owner);
        vault.updateStakingAddress(1, recipient);

        assertEq(address(vault.stakingRewards()), address(stakingRewards));
    }

    function _setDistribution(uint256 index, EulerStakingRewardsMock stakingRewards_) internal {
        rewardsDistribution.setDistribution(index, IRewardsDistribution.DistributionData(address(stakingRewards_), 100000));
    }

}
