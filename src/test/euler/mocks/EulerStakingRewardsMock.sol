// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IStakingRewards} from "../../../euler/external/IStakingRewards.sol";

contract EulerStakingRewardsMock is IStakingRewards {

  using SafeTransferLib for ERC20;

  address public immutable rewardsToken;
  address public immutable stakingToken;
  mapping(address => uint256) public balanceOf;
  mapping(address => uint256) public earned;

  constructor (address rewardsToken_, address stakingToken_) {
    rewardsToken = rewardsToken_;
    stakingToken = stakingToken_;
  }
  
  function exit() external {
    withdraw(balanceOf[msg.sender]);
    getReward();
  }

  function getReward() public {
    ERC20(rewardsToken).safeTransfer(msg.sender, earned[msg.sender]);
    earned[msg.sender] = 0;
  }

  function stake(uint256 amount) external {
    ERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount);
    balanceOf[msg.sender] += amount;
  }

  function withdraw(uint256 amount) public {
    balanceOf[msg.sender] -= amount;
    ERC20(stakingToken).safeTransfer(msg.sender, amount);
  }

  // Mocking
  function setEarned(address account, uint256 amount) external {
    earned[account] = amount;
  }

  function setBalance(address account, uint256 amount) external {
    balanceOf[account] = amount;
  }
}
