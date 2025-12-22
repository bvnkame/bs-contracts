// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EnclaveRegistry {
    struct Enclave {
        string connectURL;   // URL to connect to enclave (HTTP/WS etc)
        string pubkey;       // Public key of enclave
        uint256 version;     // Incremented every time updated
        uint256 updatedAt;   // Unix timestamp of last update
    }

    mapping(string => Enclave) private enclaves; // enclaveId => Enclave
    string[] private enclaveIds;

    event EnclaveRegistered(string indexed enclaveId, string connectURL, string pubkey, uint256 version, uint256 timestamp);
    event EnclaveUpdated(string indexed enclaveId, string connectURL, string pubkey, uint256 version, uint256 timestamp);
    event EnclaveDeleted(string indexed enclaveId);

    function registerEnclave(string memory enclaveId, string memory connectURL, string memory pubkey) public {
        require(bytes(enclaveId).length > 0, "Enclave ID required");
        require(bytes(connectURL).length > 0, "Connect URL required");
        require(bytes(pubkey).length > 0, "Public key required");
        require(enclaves[enclaveId].version == 0, "Enclave already exists");

        enclaves[enclaveId] = Enclave({
            connectURL: connectURL,
            pubkey: pubkey,
            version: 1,
            updatedAt: block.timestamp
        });

        enclaveIds.push(enclaveId);

        emit EnclaveRegistered(enclaveId, connectURL, pubkey, 1, block.timestamp);
    }

    function updateEnclave(string memory enclaveId, string memory newConnectURL, string memory newPubkey) public {
        require(bytes(newConnectURL).length > 0, "New Connect URL required");
        require(bytes(newPubkey).length > 0, "New Public key required");

        Enclave storage e = enclaves[enclaveId];
        require(e.version > 0, "Enclave not found");

        e.connectURL = newConnectURL;
        e.pubkey = newPubkey;
        e.version += 1;
        e.updatedAt = block.timestamp;

        emit EnclaveUpdated(enclaveId, newConnectURL, newPubkey, e.version, block.timestamp);
    }

    function getEnclave(string memory enclaveId) public view returns (string memory connectURL, string memory pubkey, uint256 version, uint256 updatedAt) {
        Enclave storage e = enclaves[enclaveId];
        require(e.version > 0, "Enclave not found");
        return (e.connectURL, e.pubkey, e.version, e.updatedAt);
    }

    function listEnclaveIds() public view returns (string[] memory) {
        return enclaveIds;
    }

    /// ✅ New function: get all enclaves in one call (for frontend)
    function getAllEnclaves () public view
        returns (
            string[] memory ids,
            string[] memory urls,
            string[] memory pubkeys,
            uint256[] memory versions,
            uint256[] memory timestamps
        )
    {
        uint256 count = enclaveIds.length;
        ids = new string[](count);
        urls = new string[](count);
        pubkeys = new string[](count);
        versions = new uint256[](count);
        timestamps = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            string memory id = enclaveIds[i];
            Enclave storage e = enclaves[id];

            ids[i] = id;
            urls[i] = e.connectURL;
            pubkeys[i] = e.pubkey;
            versions[i] = e.version;
            timestamps[i] = e.updatedAt;
        }
    }

    // Function to delete an enclave with a given id
    function deleteEnclave(string memory enclaveId) public {
        Enclave storage e = enclaves[enclaveId];
        require(e.version > 0, "Enclave not found");

        delete enclaves[enclaveId];

        // Remove enclaveId from the list
        uint256 count = enclaveIds.length;
        for (uint256 i = 0; i < count; i++) {
            if (keccak256(abi.encodePacked(enclaveIds[i])) == keccak256(abi.encodePacked(enclaveId))) {
                enclaveIds[i] = enclaveIds[count - 1];
                enclaveIds.pop();
                break;
            }
        }

        emit EnclaveDeleted(enclaveId);
    }
}