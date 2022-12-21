// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {IStakingRewards} from "../../../euler/external/IStakingRewards.sol";
import {IRewardsDistribution} from "../../../euler/external/IRewardsDistribution.sol";
import {IEulerEToken} from "../../../euler/external/IEulerEToken.sol";

import {StakeableEulerERC4626} from "../../../euler/staking/StakeableEulerERC4626.sol";

contract IntegrationStakeableEulerERC4626Test is Test {
    uint256 constant REWARD_INDEX = 0;
    address constant EULER = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
    IRewardsDistribution public rewardsDistribution = IRewardsDistribution(0xA9839D52E964d0ed0d6D546c27D2248Fac610c43);

    ERC20 public underlying;
    IStakingRewards public stakingRewards;
    IEulerEToken public eToken;
    StakeableEulerERC4626 public vault;
    address owner = address(0x1234);
    address recipient = address(0xDEAD);
    address alice = address(0xABCD);
    address bob = address(0xDCBA);


    function setUp() public {
        IRewardsDistribution.DistributionData memory distribution = rewardsDistribution.distributions(REWARD_INDEX);
        stakingRewards = IStakingRewards(distribution.destination);
        eToken = IEulerEToken(stakingRewards.stakingToken());
        underlying = ERC20(eToken.underlyingAsset());

        vault = new StakeableEulerERC4626(underlying, EULER, eToken, rewardsDistribution, owner);

        vm.label(address(underlying), 'Underlying');
        vm.label(address(vault), 'Vault');
        vm.label(address(stakingRewards), 'Staking Rewards');
        vm.label(address(eToken), 'eToken');
        vm.label(recipient, "Recipient");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
    }    

    function test(uint256 toDepositAlice, uint256 toDepositBob) public {
        vm.assume(toDepositAlice > 0.1 ether);
        vm.assume(toDepositBob > 0.1 ether);
        vm.assume(toDepositAlice < 5000 ether && toDepositBob < 5000 ether && toDepositAlice + toDepositBob < 5000 ether);

        // Deposit for Alice
        uint256 aliceShares = _deposit(alice, toDepositAlice);
        uint256 aliceUnderlying = _toUnderlying(aliceShares);
        assertEq(vault.totalAssets(), aliceUnderlying, 'Total Assets 1');

        // Set staking contract
        _setStakingContract(REWARD_INDEX);
        assertEq(vault.totalAssets(), aliceUnderlying, 'Total Assets 2');

        // Deposit for Bob
        uint256 bobShares = _deposit(bob, toDepositBob);
        assertEq(vault.totalAssets(), _toUnderlying(aliceShares + bobShares), 'Total Assets 3');

        // Check eToken balance
        uint256 eTokenBalance = eToken.balanceOf(address(vault));
        assertApproxEqAbs(eTokenBalance, eToken.convertUnderlyingToBalance(toDepositAlice + toDepositBob), 1, 'Vault eToken Balance 1');

        // Stake all of Bob's and half of Alice's deposit
        uint256 stakedBalance = eToken.convertUnderlyingToBalance(toDepositAlice / 2 + toDepositBob);
        uint256 balanceInContract = eTokenBalance - stakedBalance;
        _stake(stakedBalance);
        assertEq(vault.totalAssets(), _toUnderlying(aliceShares + bobShares), 'Total Assets 4');
        assertEq(eToken.balanceOf(address(vault)), balanceInContract, 'Vault eToken Balance 2');
        assertEq(stakingRewards.balanceOf(address(vault)), stakedBalance, 'Staked eToken Balance 1');
        
        // Simulate that a day has passed
        vm.warp(block.timestamp + 1 days);

        // Check reward
        (address rewardsToken, uint256 earned) = vault.reward();
        assertGt(earned, 0);

        // Claim reward
        _claim(recipient);
        assertEq(ERC20(rewardsToken).balanceOf(recipient), earned);
        assertEq(ERC20(rewardsToken).balanceOf(address(vault)), 0);
        (, uint256 emptyEarned) = vault.reward();
        assertEq(emptyEarned, 0);

        // Withdraw all of Alice's balance, so that an unstake is necessary
        uint256 underlyingInContract = eToken.balanceOfUnderlying(address(vault));
        uint256 newAliceUnderlying = vault.previewRedeem(aliceShares);
        uint256 neededToUnstake = eToken.convertUnderlyingToBalance(newAliceUnderlying - underlyingInContract);        
        uint256 extraWithdrew = FixedPointMathLib.mulDivUp(stakedBalance - neededToUnstake, 5, 100);
        uint256 leftStaking = stakedBalance - neededToUnstake - extraWithdrew;

        vm.prank(alice);
        vault.redeem(aliceShares, alice, alice);
        uint256 eTokenBalance2 = eToken.balanceOf(address(vault));
        
        assertEq(underlying.balanceOf(alice), newAliceUnderlying, 'Alice Balance');
        assertEq(stakingRewards.balanceOf(address(vault)), leftStaking, 'Staked eToken Balance 2');
        // This is a special check. Due to precision, we might be left with more eTokens thatn expected, or 
        // we might end up with one wei less than the 5% extra withdrawn
        assertGe(eTokenBalance2, extraWithdrew - 1, 'Vault eToken Balance 3'); 

        // Unstake a portion
        uint256 unstake = leftStaking / 2;
        _unstake(unstake);
        assertEq(eToken.balanceOf(address(vault)), eTokenBalance2 + unstake);
        assertEq(stakingRewards.balanceOf(address(vault)), leftStaking - unstake);

        // Simulate that another day has passed
        vm.warp(block.timestamp + 1 days);

        // Stop staking
        (, uint256 earned2) = vault.reward();
        assertGt(earned2, 0);
        _stopStaking(recipient);
        assertEq(ERC20(rewardsToken).balanceOf(recipient), earned + earned2);
        assertEq(ERC20(rewardsToken).balanceOf(address(vault)), 0);
        (, uint256 emptyEarned2) = vault.reward();
        assertEq(emptyEarned2, 0);
        assertEq(address(vault.stakingRewards()), address(0));
        assertEq(eToken.allowance(address(vault), address(stakingRewards)), 0);
    }

    function _toUnderlying(uint256 shares) internal view returns (uint256) {
        return vault.previewRedeem(shares);
    }

    function _deposit(address from, uint256 amount) internal returns (uint256 shares) {
        deal(address(underlying), from, amount);
        vm.prank(from);
        underlying.approve(address(vault), amount);
        vm.prank(from);
        return vault.deposit(amount, from);
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

    function _setStakingContract(uint256 index) internal {
        vm.prank(owner);
        vault.updateStakingAddress(index, recipient);
    }
}
