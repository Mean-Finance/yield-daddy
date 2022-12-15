// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IEulerEToken} from "../external/IEulerEToken.sol";
import {IRewardsDistribution} from "../external/IRewardsDistribution.sol";
import {IStakingRewards} from "../external/IStakingRewards.sol";

import {EulerERC4626} from "../EulerERC4626.sol";

/// @title StakeableEulerERC4626
/// @author Sam Bugs
/// @notice A ERC4626 wrapper for Euler Finance, that can handle staking
contract StakeableEulerERC4626 is EulerERC4626 {

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
    IStakingRewards stakingRewards;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(ERC20 asset_, address euler_, IEulerEToken eToken_, IRewardsDistribution rewardsDistribution_)
        EulerERC4626(asset_, euler_, eToken_)
    {
        rewardsDistribution = rewardsDistribution_;
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------

    function totalAssets() public view virtual override returns (uint256) {
        return super.totalAssets() + _getStakedBalance();
    }

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual override {
        uint256 balanceInContract = super.totalAssets();
        if (balanceInContract < assets) {
            // Need to unstake to meet the demand
            _unstake(assets - balanceInContract);
        }
        super.beforeWithdraw(assets, shares);
    }

    /// -----------------------------------------------------------------------
    /// Staking functions
    /// -----------------------------------------------------------------------

    /// @notice Returns how much was earned during staking
    function reward() public view returns (address rewardToken, uint256 earned) {
        return _calculateReward(stakingRewards);
    }

    // TODO: Only Admin
    /// @notice Allows admin to stake a certain amount of tokens
    function stake(uint256 amount) external {
        stakingRewards.stake(amount);
    }

    // TODO: Only Admin
    /// @notice Allows admin to unstake a certain amount of tokens
    function unstake(uint256 amount) external {
        _unstake(amount);
    }

    // TODO: Only Admin
    /// @notice Allows admin to claim reward and stop staking all together
    function stopStaking(address recipient) public {
        _stopStaking(recipient);
        stakingRewards = IStakingRewards(address(0));
    }

    // TODO: Only Admin
    /// @notice Allows admin to set or update a new staking contract. Will claim rewards from previous staking if available
    function updateStakingAddress(uint256 rewardIndex, address recipient) external {
        _stopStaking(recipient);

        IRewardsDistribution.DistributionData memory data = rewardsDistribution.distributions(rewardIndex);
        IStakingRewards _stakingRewards = IStakingRewards(data.destination);
        if (_stakingRewards.stakingToken() != address(eToken)) revert StakeableEulerERC4626__InvalidRewardContract();

        stakingRewards = _stakingRewards;
    }
    
    // TODO: Only Admin
    /// @notice Allows admin to claim all staking rewards
    function claimReward(address recipient) public returns (address rewardToken, uint256 earned) {
        (rewardToken, earned) = reward();
        _transferRewardToken(rewardToken, earned, recipient);
    }

    function _calculateReward(IStakingRewards _stakingRewards) public view returns (address rewardToken, uint256 earned) {
        if (address(_stakingRewards) != address(0)) {
            rewardToken = _stakingRewards.rewardsToken();
            earned = _stakingRewards.earned(address(this));
        }
    }

    function _unstake(uint256 amount) internal {
        stakingRewards.withdraw(amount);
    }

    function _getStakedBalance() internal view returns (uint256) {
        IStakingRewards _stakingRewards = stakingRewards;
        return address(_stakingRewards) == address(0)
            ? 0
            : _stakingRewards.balanceOf(address(this));
    }    

    function _stopStaking(address recipient) internal {
        IStakingRewards _stakingRewards = stakingRewards;
        if (address(_stakingRewards) != address(0)) {
            (address rewardToken, uint256 earned) = _calculateReward(_stakingRewards);
            _stakingRewards.exit();
            _transferRewardToken(rewardToken, earned, recipient);
        }
    }

    function _transferRewardToken(address rewardToken, uint256 amount, address recipient) internal {
        if (amount > 0) {
            ERC20(rewardToken).safeTransfer(recipient, amount);
        }
    }
}
