// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract User {
    struct History {
        uint32 ticket;
        uint64 timeStamp;
    }

    mapping(address => mapping(uint256 => History)) public userToHistories;

    function addHistory(uint256 _ticket) external {}
}
