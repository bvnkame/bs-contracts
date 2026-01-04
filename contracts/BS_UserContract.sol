// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";

contract UserContract {
    address public immutable factory;
    bytes32 public immutable emailHash;

    address public enclaveSigner;   
    address public enclave;

    // ASK pubkey currently active
    bytes32 public activeASK;
    uint64  public askExpiry;
    bool public keyGenerated;
    bytes32 private privateKey;

    // Whitelisted enclave PCR0
    mapping(bytes32 => bool) public allowedPCR0;

    bool public initialized;

    event PCR0Added(bytes32 pcr0, address sender);
    event PCR0Removed(bytes32 pcr0, address sender);
    event PrivateKeyGenerated(bytes32 keyHash);

    modifier onlyFactory() {
        require(msg.sender == factory, "NOT_FACTORY");
        _;
    }

    modifier onlyEnclave() {
        require(msg.sender == enclave, "NOT_ENCLAVE");
        _;
    }

    modifier onlyWithEnclaveSig(
        address user,
        bytes32 symmetricKeyHash,
        uint256 nonce,
        bytes calldata sig
    ) {
        require(
            verifyEnclaveSignature(user, symmetricKeyHash, nonce, sig),
            "INVALID_ENCLAVE_SIGNATURE"
        );
        _;
    }

    constructor(
        address _factory,
        bytes32 _emailHash,
        bytes32 _ask
    ) {
        factory = _factory;
        emailHash = _emailHash;
        activeASK = _ask;
    }

    // Only allow enclave save / backup key
    function backupKey() external  onlyEnclave {
        
    }

    /// Called once by factory, then UC is frozen
    function initialize() external onlyFactory {
        require(!initialized, "ALREADY_INIT");
        initialized = true;
    }

    function setEnclave(address _enclave) public onlyFactory {
        enclave = _enclave;
    }

    // function exportEncryptedKey(
    //     address user,
    //     bytes32 symmetricKey, 
    //     bytes32 symmetricKeyHash,
    //     uint256 nonce,
    //     bytes calldata sig
    // )
    //     external
    //     view
    //     onlyWithEnclaveSig(user, symmetricKeyHash, nonce, sig)
    //     returns (bytes memory)
    // {
    //     bytes memory plaintext = abi.encode(privateKey);
    //     bytes32 nonce = bytes12(Sapphire.randomBytes(12, "nonce"));

    //     return Sapphire.encrypt(
    //         symmetricKey,
    //         nonce,
    //         plaintext,
    //         ""
    //     );
    // }

    function exportEncryptedKey(
        bytes32 symmetricKey
    )
        external
        view
        returns (bytes32 nonce, bytes memory ciphertext)
    {
        bytes memory plaintext = abi.encode(privateKey);
        nonce = bytes32(Sapphire.randomBytes(32, bytes("my-dapp-nonce")));

        ciphertext = Sapphire.encrypt(
            symmetricKey,
            nonce,
            plaintext,
            ""
        );
    }

    function addPCR0(bytes32 pcr0) external onlyFactory {
        require(!allowedPCR0[pcr0], "EXISTS");
        allowedPCR0[pcr0] = true;

        emit PCR0Added(pcr0, msg.sender);
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

    function generateNostrKeyOnce() external onlyFactory {
        require(!keyGenerated, "KEY_EXISTS");
        generateNostrKey();
        keyGenerated = true;

        bytes32 keyHash = keccak256(
            abi.encodePacked(
                "OASIS_SAPPHIRE_PRIVATE_KEY_V1",
                privateKey
            )
        );

        emit PrivateKeyGenerated(keyHash);
    }

    function generateNostrKey() private {
        // Tạo 32 bytes ngẫu nhiên cho Nostr Private Key
        bytes32 nostrPrivateKey = bytes32(Sapphire.randomBytes(32, ""));
        privateKey = nostrPrivateKey;
    }

    function verifyEnclaveSignature(
        address user,
        bytes32 symmetricKeyHash,
        uint256 nonce,
        bytes calldata signature
    ) public view returns (bool) {
        bytes32 digest = keccak256(
            abi.encode(
                address(this),
                user,
                symmetricKeyHash,
                nonce,
                block.chainid
            )
        );

        // Ethereum signed message (khuyến nghị)
        bytes32 ethHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                digest
            )
        );

        address recovered = ecrecover(
            ethHash,
            uint8(signature[64]) + 27,
            bytes32(signature[0:32]),
            bytes32(signature[32:64])
        );

        return recovered == enclaveSigner;
    }

    function checkKeyHash(bytes32 expectedHash)
        external
        view
        returns (bool)
    {
        // Hash private key bên trong enclave
        bytes32 actualHash = keccak256(
            abi.encodePacked(privateKey)
        );

        return actualHash == expectedHash;
    }
}