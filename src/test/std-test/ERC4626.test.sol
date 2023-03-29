// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "erc4626-tests/ERC4626.test.sol" as StdTest;

/// @dev This is a16z's test, with some extra hooks
abstract contract ERC4626Test is StdTest.ERC4626Test {

    function beforeTest() public virtual {
    }

    function afterTest() public virtual {
    }

    //
    // asset
    //

    function test_asset(Init memory init) public virtual override {
        beforeTest();
        super.test_asset(init);
        afterTest();
    }

    function test_totalAssets(Init memory init) public virtual override {
        beforeTest();
        super.test_totalAssets(init);
        afterTest();
    }

    //
    // convert
    //

    function test_convertToShares(Init memory init, uint assets) public virtual override {
        beforeTest();
        super.test_convertToShares(init, assets);
        afterTest();
    }

    function test_convertToAssets(Init memory init, uint shares) public virtual override {
        beforeTest();
        super.test_convertToAssets(init, shares);
        afterTest();
    }

    //
    // deposit
    //

    function test_maxDeposit(Init memory init) public virtual override {
        beforeTest();
        super.test_maxDeposit(init);
        afterTest();
    }

    function test_previewDeposit(Init memory init, uint assets) public virtual override {
        beforeTest();
        super.test_previewDeposit(init, assets);
        afterTest();
    }

    function test_deposit(Init memory init, uint assets, uint allowance) public virtual override {
        beforeTest();
        super.test_deposit(init, assets, allowance);
        afterTest();
    }

    //
    // mint
    //

    function test_maxMint(Init memory init) public virtual override {
        beforeTest();
        super.test_maxMint(init);
        afterTest();
    }

    function test_previewMint(Init memory init, uint shares) public virtual override {
        beforeTest();
        super.test_previewMint(init, shares);
        afterTest();
    }

    function test_mint(Init memory init, uint shares, uint allowance) public virtual override {
        beforeTest();
        super.test_mint(init, shares, allowance);
        afterTest();
    }

    //
    // withdraw
    //

    function test_maxWithdraw(Init memory init) public virtual override {
        beforeTest();
        super.test_maxWithdraw(init);
        afterTest();
    }

    function test_previewWithdraw(Init memory init, uint assets) public virtual override {
        beforeTest();
        super.test_previewWithdraw(init, assets);
        afterTest();
    }

    function test_withdraw(Init memory init, uint assets, uint allowance) public virtual override {
        beforeTest();
        super.test_withdraw(init, assets, allowance);
        afterTest();
    }

    function testFail_withdraw(Init memory init, uint assets) public virtual override {
        beforeTest();
        super.testFail_withdraw(init, assets);
        afterTest();
    }

    //
    // redeem
    //

    function test_maxRedeem(Init memory init) public virtual override {
        beforeTest();
        super.test_maxRedeem(init);
        afterTest();
    }

    function test_previewRedeem(Init memory init, uint shares) public virtual override {
        beforeTest();
        super.test_previewRedeem(init, shares);
        afterTest();
    }

    function test_redeem(Init memory init, uint shares, uint allowance) public virtual override {
        beforeTest();
        super.test_redeem(init, shares, allowance);
        afterTest();
    }

    function testFail_redeem(Init memory init, uint shares) public virtual override {
        beforeTest();
        super.testFail_redeem(init, shares);
        afterTest();
    }

    //
    // round trip tests
    //

    function test_RT_deposit_redeem(Init memory init, uint assets) public virtual override {
        beforeTest();
        super.test_RT_deposit_redeem(init, assets);
        afterTest();
    }

    function test_RT_deposit_withdraw(Init memory init, uint assets) public virtual override {
        beforeTest();
        super.test_RT_deposit_withdraw(init, assets);
        afterTest();
    }

    function test_RT_redeem_deposit(Init memory init, uint shares) public virtual override {
        beforeTest();
        super.test_RT_redeem_deposit(init, shares);
        afterTest();
    }

    function test_RT_redeem_mint(Init memory init, uint shares) public virtual override {
        beforeTest();
        super.test_RT_redeem_mint(init, shares);
        afterTest();
    }

    function test_RT_mint_withdraw(Init memory init, uint shares) public virtual override {
        beforeTest();
        super.test_RT_mint_withdraw(init, shares);
        afterTest();
    }

    function test_RT_mint_redeem(Init memory init, uint shares) public virtual override {
        beforeTest();
        super.test_RT_mint_redeem(init, shares);
        afterTest();
    }

    function test_RT_withdraw_mint(Init memory init, uint assets) public virtual override {
        beforeTest();
        super.test_RT_withdraw_mint(init, assets);
        afterTest();
    }

    function test_RT_withdraw_deposit(Init memory init, uint assets) public virtual override {
        beforeTest();
        super.test_RT_withdraw_deposit(init, assets);
        afterTest();
    }
}