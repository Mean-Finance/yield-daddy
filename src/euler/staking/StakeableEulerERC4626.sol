// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IEulerEToken} from "../external/IEulerEToken.sol";
import {IRewardsDistribution} from "../external/IRewardsDistribution.sol";
import {IStakingRewards} from "../external/IStakingRewards.sol";

import {EulerERC4626} from "../EulerERC4626.sol";

/// @title StakeableEulerERC4626
/// @author Sam Bugs
/// @notice A ERC4626 wrapper for Euler Finance, that can handle staking
contract StakeableEulerERC4626 is EulerERC4626, Owned {

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    /// @notice Thrown when trying to assign an invalid rewards contract
    error StakeableEulerERC4626__InvalidRewardContract();

    /// -----------------------------------------------------------------------
    /// Libraries usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Immutable params
    /// -----------------------------------------------------------------------

    /// @notice The rewards distribution address
    IRewardsDistribution public immutable rewardsDistribution;

    /// -----------------------------------------------------------------------
    /// Mutable params
    /// -----------------------------------------------------------------------

    /// @notice The staking rewards address
    IStakingRewards public stakingRewards;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(ERC20 asset_, address euler_, IEulerEToken eToken_, IRewardsDistribution rewardsDistribution_, address owner_)
        EulerERC4626(asset_, euler_, eToken_)
        Owned(owner_)
    {
        rewardsDistribution = rewardsDistribution_;
    }

    /// -----------------------------------------------------------------------
    /// Staking functions
    /// -----------------------------------------------------------------------

    /// @notice Returns how much was earned during staking
    function reward() public view returns (address rewardsToken, uint256 earned) {
        return _calculateReward(stakingRewards);
    }

    /// @notice Allows owner to set or update a new staking contract. Will claim rewards from previous staking if available
    function updateStakingAddress(uint256 rewardIndex, address recipient) external onlyOwner {
        _stopStaking(recipient);

        IRewardsDistribution.DistributionData memory data = rewardsDistribution.distributions(rewardIndex);
        IStakingRewards stakingRewards_ = IStakingRewards(data.destination);
        if (stakingRewards_.stakingToken() != address(eToken)) revert StakeableEulerERC4626__InvalidRewardContract();

        stakingRewards = stakingRewards_;
        ERC20(address(eToken)).safeApprove(address(stakingRewards_), type(uint256).max);
    }

     /// @notice Allows owner to claim rewards and stop staking all together
    function stopStaking(address recipient) external onlyOwner {
        _stopStaking(recipient);
        stakingRewards = IStakingRewards(address(0));
    }

    /// @notice Allows owner to stake a certain amount of tokens
    function stake(uint256 amount) external onlyOwner {
        stakingRewards.stake(amount);
    }

    /// @notice Allows owner to unstake a certain amount of tokens
    function unstake(uint256 amount) external onlyOwner {
        stakingRewards.withdraw(amount);
    }

    /// @notice Allows owner to claim all staking rewards
    function claimReward(address recipient) public onlyOwner returns (address rewardsToken, uint256 earned) {
        (rewardsToken, earned) = reward();
        stakingRewards.getReward();
        _transferRewardToken(rewardsToken, earned, recipient);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    function _calculateReward(IStakingRewards stakingRewards_) public view returns (address rewardToken, uint256 earned) {
        if (address(stakingRewards_) != address(0)) {
            rewardToken = stakingRewards_.rewardsToken();
            earned = stakingRewards_.earned(address(this));
        }
    }

    function _stopStaking(address recipient) internal {
        IStakingRewards stakingRewards_ = stakingRewards;
        if (address(stakingRewards_) != address(0)) {
            ERC20(address(eToken)).safeApprove(address(stakingRewards_), 0);
            (address rewardToken, uint256 earned) = _calculateReward(stakingRewards_);
            stakingRewards_.exit();
            _transferRewardToken(rewardToken, earned, recipient);
        }
    }

    function _transferRewardToken(address rewardToken, uint256 amount, address recipient) internal {
        if (amount > 0) {
            ERC20(rewardToken).safeTransfer(recipient, amount);
        }
    }
}

