// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {IEulerEToken} from "../external/IEulerEToken.sol";
import {IRewardsDistribution} from "../external/IRewardsDistribution.sol";

import {EulerERC4626} from "../EulerERC4626.sol";

/// @title StakeableEulerERC4626
/// @author Sam Bugs
/// @notice A ERC4626 wrapper for Euler Finance, that can handle staking
contract StakeableEulerERC4626 is EulerERC4626, Owned {

    /// -----------------------------------------------------------------------
    /// Immutable params
    /// -----------------------------------------------------------------------

    /// @notice The rewards distribution address
    IRewardsDistribution public immutable rewardsDistribution;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(ERC20 asset_, address euler_, IEulerEToken eToken_, IRewardsDistribution rewardsDistribution_, address owner_)
        EulerERC4626(asset_, euler_, eToken_)
        Owned(owner_)
    {
        rewardsDistribution = rewardsDistribution_;
    }

}

