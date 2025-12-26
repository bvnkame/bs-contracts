// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { SiweAuth } from "@oasisprotocol/sapphire-contracts/contracts/auth/SiweAuth.sol";
import "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";
import "./BS_UserContract.sol";

contract SPDContract  is SiweAuth {
    address public jwtIssuer;
    address public author;
    address public admin;

    // User and contracts
    mapping(bytes32 => address) public userContracts;
    bytes32[] public allUsers;
    
    
    // A fallback private key generated inside the Enclave during deployment
    bytes32 private immutable globalPrivKey;

    event NostrSigned(address indexed user, bytes32 indexed eventHash);

    event UserContractDeployed(
        address indexed user,
        address indexed userContract,
        bytes32 emailHash
    );

    modifier isAuthor(bytes memory authToken) {
        // Use msg.sender for transactions and signed calls, fallback to
        // checking bearer.
        if (msg.sender != author && authMsgSender(authToken) != author) {
            revert("not allowed");
        }
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "NOT_ADMIN");
        _;
    }

    constructor(string memory domain) SiweAuth(domain) {
        // Generates a cryptographically secure random key within the TEE
        globalPrivKey = bytes32(Sapphire.randomBytes(32, ""));

        admin = msg.sender;
    }

    function updateAllPCR0(bytes32 newPCR0) external onlyAdmin {
        for (uint256 i = 0; i < allUsers.length; i++) {
            bytes32 ask = allUsers[i]; 
            address addr = userContracts[ask];
            UserContract(addr).addPCR0(newPCR0);
        }
    }

    function deployUserContract(
        bytes32 emailHash,
        bytes32 ask,
        bytes32[] calldata initialPCR0s
    ) external returns (address ucAddr) {
        require(userContracts[ask] == address(0), "ALREADY_EXISTS");

        UserContract uc = new UserContract(
            address(this),
            emailHash,
            initialPCR0s
        );

        ucAddr = address(uc);
        require(ucAddr != address(0), "DEPLOY_FAILED");

        userContracts[ask] = ucAddr;
        allUsers.push(ask);

        emit UserContractDeployed(msg.sender, ucAddr, emailHash);
    }

    function getAllUserContracts()
        external
        view
        returns (bytes32[] memory _users, address[] memory _contracts)
    {
        uint256 len = allUsers.length;
        _users = new bytes32[](len);
        _contracts = new address[](len);

        for (uint256 i = 0; i < len; i++) {
            bytes32 u = allUsers[i];
            _users[i] = u;
            _contracts[i] = userContracts[u];
        }
    }
}
