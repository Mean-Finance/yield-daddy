// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC4626Proxy, ERC4626} from "../base/ERC4626Proxy.sol";
import {IRewardsController} from "./external/IRewardsController.sol";

/// @title ExactlyERC4626
/// @author Sam Bugs
/// @notice ERC4626 wrapper for Exactly Finance
contract ExactlyERC4626 is ERC4626Proxy, Owned {

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(ERC4626 underlyingVault_, address owner) ERC4626Proxy(underlyingVault_) Owned(owner) { }

    /// -----------------------------------------------------------------------
    /// Exactly liquidity mining
    /// -----------------------------------------------------------------------

    /// @notice Claims liquidity mining rewards from Exactly
    function claimRewards(IRewardsController rewardsController, address to) external onlyOwner {
        rewardsController.claimAll(to);
    }
}
