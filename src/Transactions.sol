// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Transactions {
    struct TransactionDetails {
        uint32 region;
        uint8 cinema;
        bytes32[] ticketIds;
        uint64 timeStamp;
        uint64 priceTotal;
    }

    mapping(address => uint256) public userToTransactionAmount;
    mapping(address => mapping(uint256 => bytes32)) public userToTransactionId;
    mapping(bytes32 => TransactionDetails) public transactionIdToDetails;

    function addNewTransaction(
        uint256 _region,
        uint256 _cinema,
        bytes32[] calldata _ticketIds,
        uint256 _priceTotal
    ) external {
        uint256 userTransactionAmount = userToTransactionAmount[msg.sender];
        uint256 newUserTransactionAmount = userTransactionAmount + 1;
        bytes32 transactionId = keccak256(
            abi.encode(_region, _cinema, newUserTransactionAmount, msg.sender)
        );
        TransactionDetails storage transactionDetails = transactionIdToDetails[
            transactionId
        ];
        userToTransactionId[msg.sender][
            newUserTransactionAmount
        ] = transactionId;
        transactionDetails.region = uint32(_region);
        transactionDetails.cinema = uint8(_cinema);
        transactionDetails.ticketIds = _ticketIds;
        transactionDetails.priceTotal = uint64(_priceTotal);
        transactionDetails.timeStamp = uint64(block.timestamp);
    }
}
