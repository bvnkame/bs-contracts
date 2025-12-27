// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Bech32.sol";
import "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";

contract SchnorrKey {
    // bytes32 private nsec;
    bytes32 private nonce;
    address private owner;
    bytes32 private nsec;

    event KeyGenerated(bytes32 nonce);
    event PrivateKeyGenerated(bytes32 nsec);

    function generateNostrKey() public {
        bytes memory entropy = Sapphire.randomBytes(32, bytes("my-dapp-nonce"));

        nonce = bytes32(Sapphire.randomBytes(32, bytes("my-dapp-nonce")));
        
        emit KeyGenerated(nonce);

        nsec = bytes32(entropy);
    }

    function externalEncode(string memory prefix, bytes memory data) external pure returns (string memory) {
        return Bech32.encode(prefix, data); 
    }

    function getNsec() public view returns (bytes32) {
        require(msg.sender == owner, "Unauthorized");
        return nsec;
    }

    function getNonce() public view returns (bytes32) {
        require(msg.sender == owner, "Unauthorized");
        return nonce;
    }
}