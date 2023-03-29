// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title ERC4626Proxy
/// @author Sam Bugs
/// @notice Abstract base contract for proxying to other ERC4626 vaults
abstract contract ERC4626Proxy is ERC20 {

    using SafeTransferLib for ERC20;
    using SafeTransferLib for ERC4626;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC4626 public immutable underlyingVault;
    ERC20 public immutable asset;

    constructor (ERC4626 underlyingVault_) ERC20(_vaultName(underlyingVault_), _vaultSymbol(underlyingVault_), underlyingVault_.decimals()) {
        underlyingVault = underlyingVault_;
        asset = underlyingVault_.asset();
        maxApproveUnderlyingVault();
    }    

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        // Deposit to underlying
        shares = underlyingVault.deposit(assets, address(this));

        // Mint and emit
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        // Deposit to underlying
        assets = underlyingVault.mint(shares, address(this));

        // Mint and emit
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = underlyingVault.withdraw(assets, receiver, address(this));

        // Check and update allowance
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Burn and emit
        _burn(owner, shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        // Check and update allowance
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Burn
        _burn(owner, shares);

        // Redeem and emit
        assets = underlyingVault.redeem(shares, receiver, address(this));
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256) {
        return convertToAssets(underlyingVault.balanceOf(address(this)));
    }

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        return underlyingVault.convertToShares(assets);
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        return underlyingVault.convertToAssets(shares);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return underlyingVault.previewDeposit(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return underlyingVault.previewMint(shares);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return underlyingVault.previewWithdraw(assets);
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return underlyingVault.previewRedeem(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view returns (uint256) {
        return underlyingVault.maxDeposit(address(this));
    }

    function maxMint(address) public view returns (uint256) {
        return underlyingVault.maxMint(address(this));
    }

    function maxWithdraw(address owner) public view returns (uint256) {
        uint256 maxWithdrawVault = underlyingVault.maxWithdraw(address(this));
        uint256 assetsBalance = previewRedeem(balanceOf[owner]);
        return maxWithdrawVault < assetsBalance ? maxWithdrawVault : assetsBalance;
    }

    function maxRedeem(address owner) public view returns (uint256) {
        uint256 maxRedeemVault = underlyingVault.maxRedeem(address(this));
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
    function redeemAllForUnderlyingVaultToken(uint256 shares, address receiver) public returns (uint256 assets) {
        // Convert shares to assets
        assets = convertToAssets(shares);

        // Burn and emit
        _burn(msg.sender, shares);
        emit Withdraw(msg.sender, receiver, msg.sender, assets, shares);

        // Send underlying vault's tokens
        underlyingVault.safeTransfer(receiver, shares);
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
