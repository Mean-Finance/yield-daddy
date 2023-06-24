// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {CREATE3Factory} from "create3-factory/src/CREATE3Factory.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IVERC20} from "../../src/venus/external/IVERC20.sol";
import {IVComptroller} from "../../src/venus/external/IVComptroller.sol";
import {VenusERC4626Factory} from "../../src/venus/VenusERC4626Factory.sol";
import {VenusERC4626} from "../../src/venus/VenusERC4626.sol";

contract DeployScript is Script {
    function run() public returns (VenusERC4626[] memory deployed) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        VenusERC4626Factory factory = VenusERC4626Factory(0x95233D36317fBB3F989369F76532239Db0C9F35F);
        IVComptroller comptroller = IVComptroller(vm.envAddress("VENUS_COMPTROLLER_BNB"));
        address cEther = vm.envAddress("VENUS_CETHER_BNB");

        vm.startBroadcast(deployerPrivateKey);

        IVERC20[] memory allCTokens = comptroller.getAllMarkets();
        uint256 numCTokens = allCTokens.length;
        deployed = new VenusERC4626[](numCTokens);
        IVERC20 cToken;
        for (uint256 i; i < numCTokens;) {
            cToken = allCTokens[i];
            if (address(cToken) != cEther && address(cToken) != address(0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8)) {
                address vault = address(factory.createERC4626(cToken.underlying()));
                deployed[i] = VenusERC4626(vault);
            }

            unchecked {
                ++i;
            }
        }

        vm.stopBroadcast();
    }
}
