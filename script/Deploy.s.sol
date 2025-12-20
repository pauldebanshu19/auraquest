// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {Script, console} from "forge-std/Script.sol";
import {Polymarket} from "../src/Polymarket.sol";
import {PolyToken} from "../src/PolyToken.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy PolyToken
        PolyToken polyToken = new PolyToken();
        console.log("PolyToken deployed at:", address(polyToken));

        // 2. Deploy Polymarket with PolyToken address
        Polymarket polymarket = new Polymarket(address(polyToken));
        console.log("Polymarket deployed at:", address(polymarket));

        vm.stopBroadcast();
    }
}
