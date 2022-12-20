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
    address alice = address(0x1234);

    function setUp() public {
        euler = new EulerMock();
        underlying = new ERC20Mock();
        rewardsToken = new ERC20Mock();
        eToken = new EulerETokenMock(underlying, euler);
        markets = new EulerMarketsMock();        

        markets.setETokenForUnderlying(address(underlying), address(eToken));

        rewardsDistribution = new EulerRewardsDistributionMock();

        vault = new StakeableEulerERC4626(underlying, address(euler), eToken, rewardsDistribution, owner);

        stakingRewards = new EulerStakingRewardsMock(address(rewardsToken), address(eToken));
        _setDistribution(1, stakingRewards);

        underlying.mint(alice, 100000);
    }

    function testInitialization() public {
        assertEq(address(vault.rewardsDistribution()), address(rewardsDistribution));
        assertEq(vault.owner(), owner);
        assertEq(address(vault.stakingRewards()), address(0));
    }

    function testFailNotOwnerUpdateStaking() public {
        vault.updateStakingAddress(1, recipient);
    }

    function testFailInvalidIndexUpdateStaking() public {
        vm.prank(owner);
        vault.updateStakingAddress(2, recipient);
    }

    function testFailWrongTokenUpdateStaking() public {
        EulerStakingRewardsMock stakingRewards_ = new EulerStakingRewardsMock(address(rewardsToken), address(0x0101));
        _setDistribution(2, stakingRewards_);

        vm.prank(owner);
        vault.updateStakingAddress(2, recipient);
    }

    function testAddNewStakingAddress() public {       
        vm.prank(owner);
        vault.updateStakingAddress(1, recipient);

        assertEq(address(vault.stakingRewards()), address(stakingRewards));
        assertEq(eToken.allowance(address(vault), address(stakingRewards)), type(uint256).max);
    }

    function testUpdateStakingAddress() public withStakingContract {
        EulerStakingRewardsMock newStakingRewards = new EulerStakingRewardsMock(address(rewardsToken), address(eToken));        
        _setDistribution(2, newStakingRewards);

        uint256 earned = 1000;
        stakingRewards.setEarned(address(vault), earned);

        vm.prank(owner);
        vault.updateStakingAddress(2, recipient);

        // Make sure that all reward was transferred to recipient
        assertEq(rewardsToken.balanceOf(recipient), earned);
        assertEq(rewardsToken.balanceOf(address(stakingRewards)), 0);
        assertEq(rewardsToken.balanceOf(address(vault)), 0);

        // Now there is no more reward
        (, uint256 earned__) = vault.reward();
        assertEq(earned__, 0);

        // Make sure staking was updated
        assertEq(address(vault.stakingRewards()), address(newStakingRewards));
        assertEq(eToken.allowance(address(vault), address(newStakingRewards)), type(uint256).max);

        // Check allowance
        assertEq(eToken.allowance(address(vault), address(stakingRewards)), 0);
    }

    function testFailNotOwnerStaking() public {
        vault.stake(1000);
    }

    function testStaking() public withStakingContract {
        uint256 deposited = 10000;
        uint256 staked = 1000;

        _deposit(alice, deposited);
        _stake(staked);

        assertEq(eToken.balanceOf(address(vault)), deposited - staked);
        assertEq(eToken.balanceOf(address(stakingRewards)), staked);
        assertEq(stakingRewards.balanceOf(address(vault)), staked);
    }

    function testFailNotOwnerUnstaking() public {
        vault.unstake(1000);
    }

    function testUnstaking() public withStakingContract {
        uint256 deposited = 10000;
        uint256 staked = 1000;

        _deposit(alice, deposited);
        _stake(staked);
        uint256 unstake = 400;
        _unstake(unstake);

        assertEq(eToken.balanceOf(address(vault)), deposited - staked + unstake);
        assertEq(eToken.balanceOf(address(stakingRewards)), staked - unstake);
        assertEq(stakingRewards.balanceOf(address(vault)), staked - unstake);
    }

    function testReward() public withStakingContract {
        uint256 earned = 1000;
        stakingRewards.setEarned(address(vault), earned);

        (address rewardsToken_, uint256 earned_) = vault.reward();
        assertEq(earned_, earned);
        assertEq(rewardsToken_, address(rewardsToken));
    }

    function testFailNotOwnerClaimReward() public {
        vault.claimReward(recipient);
    }

    function testClaimReward() public withStakingContract {
        uint256 earned = 1000;
        stakingRewards.setEarned(address(vault), earned);

        (address rewardsToken_, uint256 earned_) = _claim(recipient);

        // Check return value
        assertEq(earned_, earned);
        assertEq(rewardsToken_, address(rewardsToken));

        // Make sure that all reward was transferred to recipient
        assertEq(rewardsToken.balanceOf(recipient), earned);
        assertEq(rewardsToken.balanceOf(address(stakingRewards)), 0);
        assertEq(rewardsToken.balanceOf(address(vault)), 0);

        // Now there is no more reward
        (, uint256 earned__) = _claim(recipient);
        assertEq(earned__, 0);
    }

    function testFailNotOwnerStopStaking() public {
        vault.stopStaking(recipient);
    }

    function testStopStaking() public withStakingContract {
        uint256 earned = 1000;
        stakingRewards.setEarned(address(vault), earned);

        _stopStaking(recipient);

        // Make sure that all reward was transferred to recipient
        assertEq(rewardsToken.balanceOf(recipient), earned);
        assertEq(rewardsToken.balanceOf(address(stakingRewards)), 0);
        assertEq(rewardsToken.balanceOf(address(vault)), 0);

        // Now there is no more reward
        (, uint256 earned__) = vault.reward();
        assertEq(earned__, 0);

        // Make sure there is no more staking
        assertEq(address(vault.stakingRewards()), address(0));

        // Check allowance
        assertEq(eToken.allowance(address(vault), address(stakingRewards)), 0);
    }

    function _deposit(address from, uint256 amount) internal {
        vm.prank(from);
        underlying.approve(address(vault), amount);
        vm.prank(from);
        vault.deposit(amount, from);
    }

    function _stake(uint256 amount) internal {
        vm.prank(owner);
        vault.stake(amount);
    }

    function _unstake(uint256 amount) internal {
        vm.prank(owner);
        vault.unstake(amount);
    }

    function _claim(address recipient_) internal returns (address rewardsToken_, uint256 earned_) {
        vm.prank(owner);
        return vault.claimReward(recipient_);
    }

    function _stopStaking(address recipient_) internal {
        vm.prank(owner);
        vault.stopStaking(recipient_);
    }

    function _setStakingContract() internal {
        vm.prank(owner);
        vault.updateStakingAddress(1, recipient);
    }

    function _setDistribution(uint256 index, EulerStakingRewardsMock stakingRewards_) internal {
        rewardsDistribution.setDistribution(index, IRewardsDistribution.DistributionData(address(stakingRewards_), 100000));
    }

    modifier withStakingContract {
        _setStakingContract();
        _;
    }

}
