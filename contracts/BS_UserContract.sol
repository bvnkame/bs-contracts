// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";

contract UserContract {
    address public immutable factory;
    bytes32 public immutable emailHash;

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

    function encryptPrivateKey(
        bytes32 symmetricKey
    )
        view
        external
        onlyEnclave
        returns (bytes32 nonce, bytes memory ciphertext)
    {
        nonce = bytes32(Sapphire.randomBytes(12, "private_nonce_seed"));

        bytes memory plaintext = abi.encode(privateKey);

        ciphertext = Sapphire.encrypt(
            symmetricKey,
            nonce,
            plaintext,
            ""
        );
    }

    function encryptPrivateKeyForEnclave(
        Sapphire.Curve25519PublicKey enclavePubKey
    )
    external
    view
    onlyEnclave
    returns (
        Sapphire.Curve25519PublicKey ephemeralPubKey,
        bytes32 nonce,
        bytes memory ciphertext
    )
    {
        // Generate ephemeral keypair
        Sapphire.Curve25519PublicKey ephPk;
        Sapphire.Curve25519SecretKey ephSk;

        (ephPk, ephSk) =
            Sapphire.generateCurve25519KeyPair(
                bytes("ephemeral-encryption-key")
            );

        bytes32 sharedSecret = Sapphire.deriveSymmetricKey(
            enclavePubKey, 
            ephSk   
        );

        nonce = bytes32(
            Sapphire.randomBytes(12, "private_key_nonce")
        );

        bytes memory plaintext = abi.encode(privateKey);

        ciphertext = Sapphire.encrypt(
            sharedSecret,
            nonce,
            plaintext,
            ""
        );

        // 6. Return ephemeral public key for enclave to decrypt
        ephemeralPubKey = ephPk;
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
}