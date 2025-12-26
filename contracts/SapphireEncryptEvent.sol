// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Sapphire } from "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";

contract EncryptedEvents {
    event Encrypted(address indexed sender, bytes32 nonce, bytes ciphertext);

    function emitEncrypted(bytes32 key, bytes calldata text) external {
        bytes32 nonce = bytes32(Sapphire.randomBytes(32, bytes("my-dapp-nonce")));
        bytes memory ad = bytes(""); // optional AAD
        bytes memory encrypted = Sapphire.encrypt(key, nonce, text, ad);
        emit Encrypted(msg.sender, nonce, encrypted);
    }
}