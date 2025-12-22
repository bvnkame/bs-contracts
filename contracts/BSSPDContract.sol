// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { SiweAuth } from "@oasisprotocol/sapphire-contracts/contracts/auth/SiweAuth.sol";
import "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";

contract SPDContract  is SiweAuth {
    address public jwtIssuer;
    address public author;

    // Mapping of user address to their encrypted Nostr Private Key
    mapping(address => bytes32) private nostrPrivKeys;
    
    // A fallback private key generated inside the Enclave during deployment
    bytes32 private immutable globalPrivKey;
    bytes32 private enclavePCR0;

    event NostrSigned(address indexed user, bytes32 indexed eventHash);

    modifier isAuthor(bytes memory authToken) {
        // Use msg.sender for transactions and signed calls, fallback to
        // checking bearer.
        if (msg.sender != author && authMsgSender(authToken) != author) {
            revert("not allowed");
        }
        _;
    }

    constructor(string memory domain) SiweAuth(domain) {
        // Generates a cryptographically secure random key within the TEE
        globalPrivKey = bytes32(Sapphire.randomBytes(32, ""));
    }

    function updateEnclavePCR0(bytes32 enclavePCR) external {
        enclavePCR0 = enclavePCR;
    }

    function getEnclavePCR0() view public returns (bytes32) {
        return enclavePCR0;
    }
}
