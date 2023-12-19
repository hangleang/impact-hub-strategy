// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

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
  
    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) QVBaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) public virtual override {}

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

    function getRecipientStatus(address _recipientId) external view override returns (Status) {}

    /// ====================================
    /// =========== Internal ===============
    /// ====================================

    function _getPayout(address _recipientId, bytes memory _data)
        internal
        view
        override
        returns (PayoutSummary memory)
    {}

    function _isValidAllocator(address _allocator) internal view virtual override returns (bool) {}

    function _getRecipientStatus(address _recipientId) internal view virtual override returns (Status) {}

    function _isAcceptedRecipient(address _recipientId) internal view virtual override returns (bool) {}

    function _hasVoiceCreditsLeft(uint256 _voiceCreditsToAllocate, uint256 _allocatedVoiceCredits)
        internal
        view
        virtual
        override
        returns (bool) {}
}