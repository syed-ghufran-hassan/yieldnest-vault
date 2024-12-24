// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.24;

import {IVault} from "src/BaseVault.sol";
import {IProvider} from "src/interface/IProvider.sol";
import {IERC20Metadata, Initializable, Math, AccessControlUpgradeable} from "src/Common.sol";
import {BaseVaultViewer} from "src/utils/BaseVaultViewer.sol";

contract MaxVaultViewer is BaseVaultViewer, AccessControlUpgradeable {
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    error ZeroAddress();
    error InvalidAssets();
    error InvalidAssetAdd(address);
    error InvalidAssetRemove(address);

    struct AssetStorage {
        mapping(address => bool) assets;
        uint256 assetsLength;
    }

    function initialize(address vault_, address admin_) external initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);

        _getViewerStorage().vault = vault_;
    }

    function getStrategies() public view returns (AssetInfo[] memory assetsInfo) {
        IVault vault = IVault(_getViewerStorage().vault);

        address[] memory allAssets = vault.getAssets();

        uint256 assetsLength = _getAssetStorage().assetsLength;
        if (allAssets.length < assetsLength) revert InvalidAssets();

        uint256 strategiesLength = allAssets.length - assetsLength;

        address[] memory strategies = new address[](strategiesLength);
        uint256[] memory balances = new uint256[](strategiesLength);

        for (uint256 i = 0; i < strategiesLength; ++i) {
            if (_getAssetStorage().assets[allAssets[i]]) continue;
            strategies[i] = allAssets[i];
            balances[i] = IERC20Metadata(allAssets[i]).balanceOf(address(vault));
        }

        return _getAssetsInfo(strategies, balances);
    }

    /**
     * @notice Internal function to get the asset storage.
     * @return $ The asset storage.
     */
    function _getAssetStorage() internal pure returns (AssetStorage storage $) {
        assembly {
            // keccak256("yieldnest.storage.asset")
            $.slot := 0x2dd192a2474c87efcf5ffda906a4b4f8a678b0e41f9245666251cfed8041e680
        }
    }

    modifier onlyVaultAsset(address asset_) {
        IVault vault = IVault(_getViewerStorage().vault);
        address[] memory assets = vault.getAssets();

        bool found;
        for (uint256 i = 0; i < assets.length; ++i) {
            if (assets[i] == asset_) {
                found = true;
            }
        }

        if (!found) revert InvalidAssetAdd(asset_);
        _;
    }

    function addKnownAsset(address asset_) external onlyRole(UPDATER_ROLE) onlyVaultAsset(asset_) {
        if (asset_ == address(0)) revert ZeroAddress();
        if (_getAssetStorage().assets[asset_]) revert InvalidAssetAdd(asset_);

        _getAssetStorage().assets[asset_] = true;
        _getAssetStorage().assetsLength += 1;
    }

    function removeKnownAsset(address asset_) external onlyRole(UPDATER_ROLE) {
        if (asset_ == address(0)) revert ZeroAddress();
        if (!_getAssetStorage().assets[asset_]) revert InvalidAssetRemove(asset_);

        _getAssetStorage().assets[asset_] = false;
        _getAssetStorage().assetsLength -= 1;
    }

    function isKnownAsset(address asset_) external view returns (bool) {
        return _getAssetStorage().assets[asset_];
    }
}
