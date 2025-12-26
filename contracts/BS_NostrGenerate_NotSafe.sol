// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";

contract NostrKeyGenerator {
    // Lưu trữ private key một cách bảo mật (chỉ contract này mới đọc được)
    mapping(address => bytes32) private userPrivateKeys;

    function generateNostrKey() external {
        // Tạo 32 bytes ngẫu nhiên cho Nostr Private Key
        bytes32 privateKey = bytes32(Sapphire.randomBytes(32, ""));
        userPrivateKeys[msg.sender] = privateKey;
    }

    function getMyKey() external view returns (bytes32) {
        // Sapphire đảm bảo rằng chỉ người gọi (msg.sender) 
        // mới thấy được kết quả trả về qua RPC bảo mật
        return userPrivateKeys[msg.sender];
    }
}