// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC4626, ERC20} from "solmate/mixins/ERC4626.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title ERC4626Proxy
/// @author Sam Bugs
/// @notice Abstract base contract for proxying to other ERC4626 vaults
abstract contract ERC4626Proxy is ERC4626 {

    using SafeTransferLib for ERC20;
    using SafeTransferLib for ERC4626;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC4626 public immutable underlyingVault;

    constructor (ERC4626 underlyingVault_) ERC4626(underlyingVault_.asset(), _vaultName(underlyingVault_), _vaultSymbol(underlyingVault_)) {
        underlyingVault = underlyingVault_;
        maxApproveUnderlyingVault();
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------

    function totalAssets() public view virtual override returns (uint256) {
        return underlyingVault.previewRedeem(underlyingVault.balanceOf(address(this)));
    }

    function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal virtual override {
        /// -----------------------------------------------------------------------
        /// Deposit assets into the underlying vault
        /// -----------------------------------------------------------------------

        underlyingVault.deposit(assets, address(this));
    }

    /// @dev Instead of overriding beforeWithdraw only, we override withdraw so that we can send the assets directly to the receiver
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        underlyingVault.withdraw(assets, receiver, address(this));

        _burn(owner, shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @dev Instead of overriding beforeWithdraw only, we override redeem so that we can send the assets directly to the receiver
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        underlyingVault.withdraw(assets, receiver, address(this));

        _burn(owner, shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function maxDeposit(address) public view override returns (uint256) {
        return underlyingVault.maxDeposit(address(this));
    }

    function maxMint(address) public view override returns (uint256) {
        return convertToShares(underlyingVault.maxDeposit(address(this)));
    }

    function maxWithdraw(address owner) public view override returns (uint256) {
        uint256 maxWithdrawVault = underlyingVault.maxWithdraw(address(this));
        uint256 assetsBalance = convertToAssets(balanceOf[owner]);
        return maxWithdrawVault < assetsBalance ? maxWithdrawVault : assetsBalance;
    }

    function maxRedeem(address owner) public view override returns (uint256) {
        uint256 maxRedeemVault = convertToShares(underlyingVault.maxWithdraw(address(this)));
        uint256 shareBalance = balanceOf[owner];
        return maxRedeemVault < shareBalance ? maxRedeemVault : shareBalance;
    }

    /*//////////////////////////////////////////////////////////////
                              AD HOC LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxApproveUnderlyingVault() public {
        asset.safeApprove(address(underlyingVault), type(uint256).max);
    }

    /// @dev In case something goes wrong with the underlying vault, we want the user to be able to claim the vault's
    ///      tokens to interact directly with it
    function previewRedeemForUnderlyingVaultToken(uint256 shares) public view returns (uint256 underlyingVaultShares, uint256 assets) {
        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        uint256 underlyingVaultBalance = underlyingVault.balanceOf(address(this));
        underlyingVaultShares = shares.mulDivDown(underlyingVaultBalance, totalSupply);
    }

    /// @dev In case something goes wrong with the underlying vault, we want the user to be able to claim the vault's
    ///      tokens to interact directly with it
    function redeemForUnderlyingVaultToken(uint256 shares, address receiver) public returns (uint256 underlyingVaultShares, uint256 assets) {
        // Calculate underlying vault's shares and assets
        (underlyingVaultShares, assets) = previewRedeemForUnderlyingVaultToken(shares);

        // Burn and emit
        _burn(msg.sender, shares);
        emit Withdraw(msg.sender, receiver, msg.sender, assets, shares);

        // Send underlying vault's tokens
        underlyingVault.safeTransfer(receiver, underlyingVaultShares);
    }

    /// -----------------------------------------------------------------------
    /// ERC20 metadata generation
    /// -----------------------------------------------------------------------

    function _vaultName(ERC4626 underlyingVault_) internal view virtual returns (string memory vaultName) {
        vaultName = string.concat("ERC4626 Proxy ", underlyingVault_.name());
    }

    function _vaultSymbol(ERC4626 underlyingVault_) internal view virtual returns (string memory vaultSymbol) {
        vaultSymbol = string.concat("pr", underlyingVault_.symbol());
    }
}
