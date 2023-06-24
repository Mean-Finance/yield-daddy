// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {CREATE3Factory} from "create3-factory/src/CREATE3Factory.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IVComptroller} from "../../src/venus/external/IVComptroller.sol";
import {VenusERC4626Factory} from "../../src/venus/VenusERC4626Factory.sol";
import {VenusERC4626} from "../../src/venus/VenusERC4626.sol";

contract DeployScript is Script {
    function run() public returns (VenusERC4626Factory deployed) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        CREATE3Factory create3 = CREATE3Factory(0x9fBB3DF7C40Da2e5A0dE984fFE2CCB7C47cd0ABf);
        IVComptroller comptroller = IVComptroller(vm.envAddress("VENUS_COMPTROLLER_BNB"));
        address cEther = vm.envAddress("VENUS_CETHER_BNB");
        address rewardRecipient = vm.envAddress("VENUS_REWARDS_RECIPIENT_BNB");

        vm.startBroadcast(deployerPrivateKey);

        deployed = VenusERC4626Factory(
            create3.deploy(
                keccak256("VenusERC4626Factory"),
                bytes.concat(
                    type(VenusERC4626Factory).creationCode, abi.encode(comptroller, cEther, rewardRecipient)
                )
            )
        );

        vm.stopBroadcast();
    }
}
