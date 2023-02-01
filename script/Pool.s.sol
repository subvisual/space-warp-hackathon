// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@forge-std/Script.sol";
import "../src/Pool.sol";

contract PoolScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CosmicFil _cosmicFil = new CosmicFil("CosmicFil", "CFA");
        new Pool(address(_cosmicFil));

        vm.stopBroadcast();
    }
}
