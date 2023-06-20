// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {IVERC20} from "./IVERC20.sol";

interface IVComptroller {
    function getXVSAddress() external view returns (address);
    function getAllMarkets() external view returns (IVERC20[] memory);
    function allMarkets(uint256 index) external view returns (IVERC20);
    function claimVenus(address[] memory holders, IVERC20[] memory cTokens, bool borrowers, bool suppliers) external;
    function mintGuardianPaused(IVERC20 cToken) external view returns (bool);
}
