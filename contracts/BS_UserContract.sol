// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract UserContract {
    address public immutable factory;
    bytes32 public immutable emailHash;

    // ASK pubkey currently active
    bytes32 public activeASK;
    uint64  public askExpiry;

    // Whitelisted enclave PCR0
    mapping(bytes32 => bool) public allowedPCR0;

    bool public initialized;

    modifier onlyFactory() {
        require(msg.sender == factory, "NOT_FACTORY");
        _;
    }

    constructor(
        bytes32 _emailHash,
        bytes32[] memory _initialPCR0s
    ) {
        factory = msg.sender;
        emailHash = _emailHash;

        for (uint i = 0; i < _initialPCR0s.length; i++) {
            allowedPCR0[_initialPCR0s[i]] = true;
        }
    }

    /// Called once by factory, then UC is frozen
    function initialize() external onlyFactory {
        require(!initialized, "ALREADY_INIT");
        initialized = true;
    }

    /// Activate ASK after JWT approval
    function activateASK(
        bytes32 askPubkey,
        uint64 expiry,
        bytes32 enclavePCR0
    ) external {
        require(allowedPCR0[enclavePCR0], "PCR0_NOT_ALLOWED");
        require(block.timestamp < expiry, "EXPIRED");

        // Sapphire: state writes are encrypted
        activeASK = askPubkey;
        askExpiry = expiry;
    }

    function isASKActive(bytes32 askPubkey) external view returns (bool) {
        return activeASK == askPubkey && block.timestamp < askExpiry;
    }
}