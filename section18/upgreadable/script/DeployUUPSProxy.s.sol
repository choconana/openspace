// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/nft_market/NFTMarketV1.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "../lib/forge-std/src/Script.sol";

contract DeployUUPSProxy is Script {
    function run() public {

        vm.startBroadcast();
        address owner = 0xD571Cb930A525c83D7D2B7442a34b09c5F1cCa3E;
        // Encode the initializer function call
        // deploy
        // address proxy = deployV1(owner);

        // upgrade
        address proxy = upgrade(owner);

        vm.stopBroadcast();
        // Log the proxy address
        console.log("UUPS Proxy Address:", address(proxy));
    }

    function deployV1(address owner) public returns (address) {
        address _implementation = 0x2044E2869D5E8b464d1282afa483F3DB240ecD44; // v1

        bytes memory data = abi.encodeWithSelector(
            NFTMarketV1(_implementation).initialize.selector,
            0x8139e2D53Ef38caDEf4693E1F480356CC4C65dfF,
            0x02711d896B761D3CC5246233ea9893aEca058aB3,
            owner // Initial owner/admin of the contract
        );

        // Deploy the proxy contract with the implementation address and initializer
        ERC1967Proxy proxy = new ERC1967Proxy(_implementation, data);
        return address(proxy);
    }

    function upgrade(address owner) public returns (address) {
        ERC1967Proxy proxy = ERC1967Proxy(payable(0x54546d42695023c70C303BDB110cA7b2e3d7787d));
        Upgrades.upgradeProxy(address(proxy), "NFTMarketV2.sol:NFTMarketV2", "", owner);
        return address(proxy);
    }
}