// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Original contract can be found under the following link:
// https://github.com/Synthetixio/synthetix/blob/master/contracts/interfaces/IRewardsDistribution.sol
interface IRewardsDistribution {
    // Structs
    struct DistributionData {
        address destination;
        uint amount;
    }

    // Views
    function distributionsLength() external view returns (uint);

    function distributions(uint256 index) external view returns (DistributionData memory);

    // Mutative Functions
    function distributeRewards() external returns (bool);
}