// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.24;

import {IVault} from "src/BaseVault.sol";
import {BaseVerifyScript} from "script/BaseVerifyScript.sol";

// FOUNDRY_PROFILE=mainnet forge script VerifyYnBTCkStrategy
contract VerifyMaxVault is BaseVerifyScript {
    function symbol() public view virtual override returns (string memory) {
        return "ynBNBx";
    }

    function run() public {
        _setup();
        _loadDeployment();
        verify();
    }

    function verify() public view {
        assertNotEq(address(vault), address(0), "vault is not set");

        assertEq(vault.name(), "YieldNest Restaked BTC - Kernel", "name is invalid");
        assertEq(vault.symbol(), "ynBTCk", "symbol is invalid");
        assertEq(vault.decimals(), 18, "decimals is invalid");
        assertEq(vault.provider(), address(rateProvider), "provider is invalid");
        assertEq(vault.baseWithdrawalFee(), 100000, "base withdrawal fee is invalid");
        assertEq(vault.countNativeAsset(), false, "count native asset is invalid");
        assertTrue(vault.alwaysComputeTotalAssets(), "always compute total assets is invalid");

        address[] memory assets = vault.getAssets();

        assertEq(assets[0], contracts.WBNB(), "assets[0] is invalid");
        IVault.AssetParams memory asset;
        if (contracts.YNWBNBK() != address(0x0b)) {
            (bool isIncluded, uint256 index) = _checkForAsset(contracts.YNWBNBK());
            assertTrue(isIncluded, "YNWBNBK is invalid");
            assertGt(index, 0, "YNWBNBK invalid index");
            assertEq(vault.buffer(), contracts.YNWBNBK(), "incorrect buffer");
            _verifyDepositRule(vault, contracts.YNWBNBK(), address(vault));
            _verifyWithdrawRule(vault, contracts.YNWBNBK(), address(vault));
            _verifyDepositRule(vault, contracts.YNWBNBK(), contracts.WBNB());
            _verifyWithdrawRule(vault, contracts.YNWBNBK(), contracts.WBNB());
            _verifyApprovalRule(vault, contracts.YNWBNBK(), contracts.WBNB());

            asset = vault.getAsset(contracts.WBNB());
            assertEq(asset.decimals, 18, "asset[1].decimals is invalid");
            assertEq(asset.active, true, "asset[1].active is invalid");
            assertEq(asset.index, 1, "asset[1].index is invalid");
        }

        if (contracts.YNCLISBNBK() != address(0x0c)) {
            (bool isIncluded, uint256 index) = _checkForAsset(contracts.YNCLISBNBK());
            assertTrue(isIncluded, "YNCLISBNBK is invalid");
            assertGt(index, 0, "YNCLISBNBK invalid index");

            asset = vault.getAsset(contracts.YNCLISBNBK());
            assertEq(asset.decimals, 18, "asset[1].decimals is invalid");
            assertEq(asset.active, false, "asset[1].active is invalid");
        }

        _verifyApprovalRule(vault, address(vault), contracts.WBNB());
        _verifyWithdrawRule(vault, address(vault), contracts.WBNB());
        _verifyDepositRule(vault, address(vault), contracts.WBNB());

        assertFalse(vault.paused());

        _verifyDefaultRoles(vault);
        _verifyTemporaryRoles(vault);
        _verifyViewer();
    }

    function _checkForAsset(address asset) internal view returns (bool isIncluded, uint256 index) {
        address[] memory assets = vault.getAssets();

        for (uint256 i; i < assets.length;) {
            if (assets[i] == asset) {
                isIncluded = true;
                index = i;
                break;
            }
            {
                i++;
            }
        }
    }
}
