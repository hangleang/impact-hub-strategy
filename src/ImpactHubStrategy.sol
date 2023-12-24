// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// External Libraries
import {IHats} from "hats-protocol/Interfaces/IHats.sol";
import {IHatsIdUtilities} from "hats-protocol/Interfaces/IHatsIdUtilities.sol";

// Core Contracts
import {MicroGrantsHatsStrategy} from "allo/contracts/strategies/_poc/micro-grants/MicroGrantsHatsStrategy.sol";

// Internal Libraries
import {Metadata} from "allo/contracts/core/libraries/Metadata.sol";

import {IAlloWithPoolCreation} from "./interfaces/IAlloWithPoolCreation.sol";

/// @title Impact Hub Strategy contract
contract ImpactHubStrategy is MicroGrantsHatsStrategy {
    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Wearer of HatId is allowed to register
    uint256[] public recipientHatIds;

    constructor(address _allo, string memory _name) MicroGrantsHatsStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    // @notice Initialize the strategy
    /// @dev This will revert if the strategy is already initialized and 'msg.sender' is not the 'Allo' contract.
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    /// @custom:data (bool useRegistryAnchor; uint64 allocationStartTime,
    ///    uint64 allocationEndTime, uint256 approvalThreshold, uint256 maxRequestedAmount), uint256 _hatId
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (InitializeParams memory initializeParams, address _hats, uint256 _allocatorHatId, uint256[] memory _recipientHatIds) =
            abi.decode(_data, (InitializeParams, address, uint256, uint256[]));
        __MicroGrants_init(_poolId, initializeParams);

        if (_hats == address(0)) revert ZERO_ADDRESS();
        hats = IHats(_hats);
        hatId = _allocatorHatId;

        uint256 hatLength = _recipientHatIds.length;
        uint32 topHatDomain;
        uint256 i = 0;
        for (; i < hatLength;) {
            if (i == 0) {
                topHatDomain = IHatsIdUtilities(address(hats)).getTopHatDomain(_recipientHatIds[i]);
            } else if (topHatDomain != IHatsIdUtilities(address(hats)).getTopHatDomain(_recipientHatIds[i])) {
                revert INVALID();
            }

            unchecked {
                i++;
            }
        }

        recipientHatIds = _recipientHatIds;
        emit Initialized(_poolId, _data);
    }

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

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Hook called before registering a recipient.
    /// @param _sender The address of the sender
    function _beforeRegisterRecipient(bytes memory, address _sender) internal virtual override {
        bool hasHat = false;
        uint256 hatLength = recipientHatIds.length;
        uint256 i = 0;
        for (; i < hatLength;) {
            hasHat = hats.isWearerOfHat(_sender, recipientHatIds[i]);
            if (hasHat) {
                break;
            }

            unchecked {
                i++;
            }
        }

        if (!hasHat) {
            revert UNAUTHORIZED();
        }
    }
}
