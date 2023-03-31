// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IRewardsController {
  function claimAll(address to) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}
