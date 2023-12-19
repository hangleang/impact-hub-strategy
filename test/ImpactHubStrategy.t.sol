// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Custom Strategy
import {ImpactHubStrategy} from "src/ImpactHubStrategy.sol";

// Strategy Interface
import {IStrategy} from "allo/contracts/core/interfaces/IStrategy.sol";

// Test libraries
import {AlloSetup} from "allo/test/foundry/shared/AlloSetup.sol";
import {RegistrySetupFull} from "allo/test/foundry/shared/RegistrySetup.sol";

import {EventSetup} from "allo/test/foundry/shared/EventSetup.sol";

contract StrategyTest is Test, EventSetup, AlloSetup, RegistrySetupFull {
    ImpactHubStrategy strategy;

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        strategy = new ImpactHubStrategy(address(allo()), "Strategy Name");
    }
}
