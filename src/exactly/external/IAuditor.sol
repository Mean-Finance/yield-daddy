// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IMarket} from './IMarket.sol';

interface IAuditor {
  function allMarkets() external view returns (IMarket[] memory);
}