// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import {IRewardsDistribution} from "../../../euler/external/IRewardsDistribution.sol";

contract EulerRewardsDistributionMock is IRewardsDistribution {

  mapping(uint256 => DistributionData) private _distributions;

  function setDistribution(uint256 index, DistributionData calldata data) external {
    _distributions[index] = data;
  }

  function distributions(uint256 index) external view returns (DistributionData memory) {
    return _distributions[index];
  }
    
}
