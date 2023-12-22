// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Core Contracts
import {MicroGrantsHatsStrategy} from "allo/contracts/strategies/_poc/micro-grants/MicroGrantsHatsStrategy.sol";

// Internal Libraries
import {Metadata} from "allo/contracts/core/libraries/Metadata.sol";

import {IAlloWithPoolCreation} from "./interfaces/IAlloWithPoolCreation.sol";

/// @title Impact Hub Strategy contract
contract ImpactHubStrategy is MicroGrantsHatsStrategy {
    constructor(address _allo, string memory _name) MicroGrantsHatsStrategy(_allo, _name) {}

    /// @notice Propose an initiative
    /// @param _data The data to be decoded
    /// @custom:data (address registryAnchor, address recipient, uint256 requestedAmount, Metadata metadata, bytes poolCreationData)
    /// @custom:recipient The recipient here is used only to compatible with the existing strategy, the actual recipient is the pool itself 
    /// @param _sender The sender of the transaction
    /// @return recipientId Returns the recipient id
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        virtual
        override
        returns (address recipientId)
    {
        address registryAnchor;
        uint256 requestedAmount;
        Metadata memory metadata;
        bytes memory poolCreationData;
        (registryAnchor,, requestedAmount, metadata, poolCreationData) =
            abi.decode(_data, (address, address, uint256, Metadata, bytes));

        bytes32 _profileId;
        address _strategy;
        bytes memory _initStrategyData;
        address _token;
        uint256 _amount;
        Metadata memory _metadata;
        address[] memory _managers;
        (_profileId, _strategy, _initStrategyData, _token, _amount, _metadata, _managers) = abi.decode(poolCreationData, (bytes32, address, bytes, address, uint256, Metadata, address[]));
        
        uint256 poolId = allo.isCloneableStrategy(_strategy) 
            ? IAlloWithPoolCreation(address(allo)).createPool(_profileId, _strategy, _initStrategyData, _token, _amount, _metadata, _managers)
            : IAlloWithPoolCreation(address(allo)).createPoolWithCustomStrategy(_profileId, _strategy, _initStrategyData, _token, _amount, _metadata, _managers);

        return super._registerRecipient(abi.encode(registryAnchor, allo.getStrategy(poolId), requestedAmount, metadata), _sender);
    }
}
