// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {IMarket} from "./external/IMarket.sol";
import {IAuditor} from "./external/IAuditor.sol";
import {ERC4626Factory} from "../base/ERC4626Factory.sol";
import {ExactlyERC4626} from "./ExactlyERC4626.sol";

/// @title ExactlyERC4626Factory
/// @author Sam Bugs
/// @notice Factory for creating ExactlyERC4626 contracts
contract ExactlyERC4626Factory is ERC4626Factory, Owned {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    /// @notice Thrown when trying to deploy an ExactlyERC4626 vault using an asset without a market
    error ExactlyERC4626Factory__MarketNonexistent();

    /// -----------------------------------------------------------------------
    /// Immutable params
    /// -----------------------------------------------------------------------

    /// @notice The Exactly auditor address
    IAuditor public immutable auditor;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(IAuditor auditor_, address owner_) Owned(owner_) {
        auditor = auditor_;
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @inheritdoc ERC4626Factory
    function createERC4626(ERC20 asset) external virtual override returns (ERC4626 vault) {        
        ERC4626 underlyingVault = _findUnderlyingVaultOrFail(asset);
        vault = ERC4626(address(new ExactlyERC4626{salt: bytes32(0)}(underlyingVault, owner)));
        emit CreateERC4626(asset, vault);
    }

    /// @inheritdoc ERC4626Factory
    function computeERC4626Address(ERC20 asset) external view virtual override returns (ERC4626 vault) {
        ERC4626 underlyingVault = _findUnderlyingVaultOrFail(asset);
        vault = ERC4626(
            _computeCreate2Address(
                keccak256(
                    abi.encodePacked(
                        // Deployment bytecode:
                        type(ExactlyERC4626).creationCode,
                        // Constructor arguments:
                        abi.encode(underlyingVault, owner)
                    )
                )
            )
        );
    }

    function _findUnderlyingVaultOrFail(ERC20 asset) internal view returns (ERC4626) {       
        IMarket[] memory allMarkets = auditor.allMarkets();
        for (uint256 i; i < allMarkets.length;) {
            IMarket market = allMarkets[i];
            if (market.asset() == address(asset)) {
                return ERC4626(address(market));
            }
            unchecked {
                ++i;
            }
        }
        revert ExactlyERC4626Factory__MarketNonexistent();
    }
}
