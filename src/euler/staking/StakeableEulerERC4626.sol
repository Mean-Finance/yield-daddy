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
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------

    function totalAssets() public view virtual override returns (uint256) {
        return super.totalAssets() + _getStakedBalance();
    }

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual override {
        uint256 balanceInContract = super.totalAssets();
        if (balanceInContract < assets) {
            // Need to unstake to meet the demand
            stakingRewards.withdraw(assets - balanceInContract);
        }
        super.beforeWithdraw(assets, shares);
    }

    /// -----------------------------------------------------------------------
    /// Staking functions
    /// -----------------------------------------------------------------------

    /// @notice Allows owner to set or update a new staking contract. Will claim rewards from previous staking if available
    function updateStakingAddress(uint256 rewardIndex, address /*recipient*/) external onlyOwner {
        // TODO: Claim rewards if was staking on another contract

        IRewardsDistribution.DistributionData memory data = rewardsDistribution.distributions(rewardIndex);
        IStakingRewards stakingRewards_ = IStakingRewards(data.destination);
        if (stakingRewards_.stakingToken() != address(eToken)) revert StakeableEulerERC4626__InvalidRewardContract();

        stakingRewards = stakingRewards_;
        ERC20(address(eToken)).safeApprove(address(stakingRewards_), type(uint256).max);
    }

    /// @notice Allows owner to stake a certain amount of tokens
    function stake(uint256 amount) external onlyOwner {
        stakingRewards.stake(amount);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    function _getStakedBalance() internal view returns (uint256) {
        IStakingRewards _stakingRewards = stakingRewards;
        return address(_stakingRewards) == address(0)
            ? 0
            : _stakingRewards.balanceOf(address(this));
    }   
}

