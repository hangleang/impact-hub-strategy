// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// External Libraries
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {IHats} from "hats-protocol/Interfaces/IHats.sol";
import {IHatsIdUtilities} from "hats-protocol/Interfaces/IHatsIdUtilities.sol";

// Intefaces
import {IAllo} from "allo/contracts/core/interfaces/IAllo.sol";
import {IRegistry} from "allo/contracts/core/interfaces/IRegistry.sol";

// Core Contracts
import {QVBaseStrategy} from "allo/contracts/strategies/qv-base/QVBaseStrategy.sol";

// Internal Libraries
import {Metadata} from "allo/contracts/core/libraries/Metadata.sol";

/// @title QV Hats Strategy contract
contract QVHatsStrategy is QVBaseStrategy {
    event AllocatedWithHat(
        address indexed recipientId, address indexed _sender, uint256 indexed hatId, uint256 voiceCreditsToAllocate
    );

    /// ================================
    /// ========== Storage =============
    /// ================================
    struct InitializeHatsParams {
        InitializeParams params;
        address hats;
        uint256[] hatIds;
        uint256[] maxVoiceCreditsPerHatId;
    }

    /// @notice Hats protocol contract
    IHats public hats;

    /// @notice Wearer of HatId is allowed to allocate and register
    uint256[] public hatIds;

    /// @notice Mapping of hatId => maxVoiceCredits
    mapping(uint256 => uint256) public maxVoiceCreditsPerHatId;

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
        (InitializeHatsParams memory initializeHatsParams) = abi.decode(_data, (InitializeHatsParams));
        __ImpactHubStrategy_init(poolId, initializeHatsParams);

        emit Initialized(_poolId, _data);
    }

    /// @dev Internal initialize function that sets the poolId in the base strategy
    function __ImpactHubStrategy_init(uint256 _poolId, InitializeHatsParams memory _initializeHatsParams) internal {
        __QVBaseStrategy_init(_poolId, _initializeHatsParams.params);

        uint256 hatLength = _initializeHatsParams.hatIds.length;
        if (hatLength != _initializeHatsParams.maxVoiceCreditsPerHatId.length) {
            revert INVALID();
        }
        if (_initializeHatsParams.hats == address(0)) revert ZERO_ADDRESS();
        hats = IHats(_initializeHatsParams.hats);

        uint32 topHatDomain;
        uint256 i = 0;
        for (; i < hatLength;) {
            uint256 hatId = _initializeHatsParams.hatIds[i];
            if (i == 0) {
                topHatDomain = IHatsIdUtilities(address(hats)).getTopHatDomain(hatId);
            } else if (topHatDomain != IHatsIdUtilities(address(hats)).getTopHatDomain(hatId)) {
                revert INVALID();
            }

            hatIds.push(hatId);
            maxVoiceCreditsPerHatId[hatId] = _initializeHatsParams.maxVoiceCreditsPerHatId[i];

            unchecked {
                i++;
            }
        }
    }

    /// ====================================
    /// ======== Strategy Methods ==========
    /// ====================================

    // /// @notice Register to the pool
    // /// @param _data The data to be decoded
    // /// @param _sender The sender of the transaction
    // function _registerRecipient(bytes memory _data, address _sender) internal override returns (address recipientId) {}

    /// @notice Allocate votes to a recipient
    /// @param _data The data
    /// @param _sender The sender of the transaction
    /// @dev Only the pool manager(s) can call this function
    function _allocate(bytes memory _data, address _sender) internal override {
        (address recipientId, uint256 hatId, uint256 voiceCreditsToAllocate) =
            abi.decode(_data, (address, uint256, uint256));

        // spin up the structs in storage for updating
        Recipient storage recipient = recipients[recipientId];
        Allocator storage allocator = allocators[_sender];

        if (!hats.isWearerOfHat(_sender, hatId)) {
            revert UNAUTHORIZED();
        }

        if (!_isAcceptedRecipient(recipientId)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        if (!_hasVoiceCreditsLeft(voiceCreditsToAllocate + allocator.voiceCredits, maxVoiceCreditsPerHatId[hatId])) {
            revert INVALID();
        }

        _qv_allocate(allocator, recipient, recipientId, voiceCreditsToAllocate, _sender);

        emit AllocatedWithHat(recipientId, _sender, hatId, voiceCreditsToAllocate);
    }

    // /// @notice Distribute the upcoming milestone
    // /// @param _sender The sender of the distribution
    // function _distribute(address[] memory _recipientIds, bytes memory, address _sender) internal virtual override {}

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
        uint256 hatLength = hatIds.length;
        uint256 i = 0;
        for (; i < hatLength;) {
            if (hats.isWearerOfHat(_allocator, hatIds[i])) {
                return true;
            }

            unchecked {
                i++;
            }
        }

        return false;
    }

    // function _getRecipientStatus(address _recipientId) internal view virtual override returns (Status) {
    //     return _isAcceptedRecipient(_recipientId) ? Status.Accepted : Status.Rejected;
    // }

    function _isAcceptedRecipient(address _recipientId) internal view virtual override returns (bool) {
        return _isValidAllocator(_recipientId);
    }

    /// @notice check if allocator has voice credits left
    /// @param _voiceCredits The sum of usedVoiceCredits with voiceCreditsToAllocate
    /// @param _maxVoiceCredits The maxVoiceCredit of the hat wearer
    function _hasVoiceCreditsLeft(uint256 _voiceCredits, uint256 _maxVoiceCredits)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return _voiceCredits <= _maxVoiceCredits;
    }

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
