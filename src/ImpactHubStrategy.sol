// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {IHats} from "hats/Interfaces/IHats.sol";

// Intefaces
import {IAllo} from "allo/contracts/core/interfaces/IAllo.sol";
import {IRegistry} from "allo/contracts/core/interfaces/IRegistry.sol";

// Core Contracts
import {BaseStrategy} from "allo/contracts/strategies/BaseStrategy.sol";
import {QVBaseStrategy} from "allo/contracts/strategies/qv-base/QVBaseStrategy.sol";

// Internal Libraries
import {Metadata} from "allo/contracts/core/libraries/Metadata.sol";

/// @title Impact Hub Strategy contract
contract ImpactHubStrategy is QVBaseStrategy {
    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Hats protocol contract
    IHats public hats;

    /// @notice Wearer of HatId is allowed to allocate
    uint256 public hatId;
  
    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) QVBaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    // @notice Initialize the strategy
    /// @dev This will revert if the strategy is already initialized and 'msg.sender' is not the 'Allo' contract.
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    /// @custom:data (bool registryGating, bool metadataRequired, uint256 reviewThreshold, 
    ///    uint64 registrationStartTime, uint64 registrationEndTime, uint64 allocationStartTime, uint64 allocationEndTime), 
    ///    address _hats, uint256 _hatId
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (InitializeParams memory initializeParams, address _hats, uint256 _hatId) =
            abi.decode(_data, (InitializeParams, address, uint256));
        __QVBaseStrategy_init(_poolId, initializeParams);

        if (_hats == address(0)) revert ZERO_ADDRESS();
        hats = IHats(_hats);
        hatId = _hatId;
        emit Initialized(_poolId, _data);
    }

    /// ====================================
    /// ======== Strategy Methods ==========
    /// ====================================

    /// @notice Register to the pool
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    function _registerRecipient(bytes memory _data, address _sender) internal override returns (address recipientId) {}

    /// @notice Allocate amount to recipent for direct grants
    /// @param _data The data to be decoded
    /// @param _sender The sender of the allocation
    function _allocate(bytes memory _data, address _sender) internal virtual override {}

    /// @notice Distribute the upcoming milestone
    /// @param _sender The sender of the distribution
    function _distribute(address[] memory _recipientIds, bytes memory, address _sender) internal virtual override {}

    /// ====================================
    /// ============= Views ================
    /// ====================================

    function getRecipientStatus(address _recipientId) external view override returns (Status) {
        return _getRecipientStatus(_recipientId);
    }

    /// ====================================
    /// =========== Internal ===============
    /// ====================================

    function _getPayout(address _recipientId, bytes memory _data)
        internal
        view
        override
        returns (PayoutSummary memory)
    {}

    /// @notice Checks if address is valid allocator.
    /// @param _allocator The allocator address
    /// @return Returns true if address is wearer of hatId
    function _isValidAllocator(address _allocator) internal view virtual override returns (bool) {
        return hats.isWearerOfHat(_allocator, hatId);
    }

    // function _getRecipientStatus(address _recipientId) internal view virtual override returns (Status) {
    //     return _isAcceptedRecipient(_recipientId) ? Status.Accepted : Status.Rejected;
    // }

    function _isAcceptedRecipient(address _recipientId) internal view virtual override returns (bool) {
        return hats.isWearerOfHat(_recipientId, hatId);
    }

    function _hasVoiceCreditsLeft(uint256 _voiceCreditsToAllocate, uint256 _allocatedVoiceCredits)
        internal
        view
        virtual
        override
        returns (bool) {}

    /// ====================================
    /// ============= Hook =================
    /// ====================================

    /// @notice Hook called before allocation to check if the sender is an allocator
    /// @param _sender The sender of the transaction
    function _beforeAllocate(bytes memory, address _sender) internal view override {
        if (!_isValidAllocator(_sender)) revert UNAUTHORIZED();
    }

    /// @notice Hook called before allocation to check if the sender is an allocator
    /// @param _sender The sender of the transaction
    function _beforeRegisterRecipient(bytes memory, address _sender) internal view override {
        if (!_isValidAllocator(_sender)) revert UNAUTHORIZED();
    }
}
