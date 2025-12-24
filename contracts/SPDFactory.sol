// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./BSUserContract.sol";

contract SPDFactory {
    /// emailHash → UserContract
    mapping(bytes32 => address) private users;

    event UserCreated(
        bytes32 indexed emailHash,
        address userContract
    );

    function getUser(bytes32 emailHash) external view returns (address) {
        return users[emailHash];
    }

    function createUser(
        bytes32 emailHash,
        bytes32[] calldata initialPCR0s
    ) external returns (address) {
        require(users[emailHash] == address(0), "USER_EXISTS");

        UserContract uc = new UserContract(
            emailHash,
            initialPCR0s
        );

        // finalize
        uc.initialize();

        users[emailHash] = address(uc);

        emit UserCreated(emailHash, address(uc));
        return address(uc);
    }
}