// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Transactions {
    struct TransactionDetails {
        uint32 region;
        uint8 cinema;
        bytes32[] ticketIds;
        uint64 timeStamp;
        uint64 priceTotal;
    }

    mapping(uint256 => mapping(uint256 => uint256))
        public cinemaToTransactionAmount;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bytes32)))
        public cinemaToTransactionId;
    mapping(address => uint256) public userToTransactionAmount;
    mapping(address => mapping(uint256 => bytes32)) public userToTransactionId;
    mapping(bytes32 => TransactionDetails) public transactionIdToDetails;

    function addNewTransaction(
        uint256 _region,
        uint256 _cinema,
        bytes32[] calldata _ticketIds,
        uint256 _priceTotal
    ) external {
        uint256 cinemaTransactionAmount = cinemaToTransactionAmount[_region][
            _cinema
        ];
        uint256 userTransactionAmount = userToTransactionAmount[msg.sender];
        uint256 newCinemaTransactionAmount = cinemaTransactionAmount + 1;
        uint256 newUserTransactionAmount = userTransactionAmount + 1;
        bytes32 transactionId = keccak256(
            abi.encode(
                _region,
                _cinema,
                newCinemaTransactionAmount,
                newUserTransactionAmount,
                msg.sender
            )
        );
        TransactionDetails storage transactionDetails = transactionIdToDetails[
            transactionId
        ];
        cinemaToTransactionId[_region][_cinema][
            newCinemaTransactionAmount
        ] = transactionId;
        userToTransactionId[msg.sender][
            newUserTransactionAmount
        ] = transactionId;
        transactionDetails.region = uint32(_region);
        transactionDetails.cinema = uint8(_cinema);
        transactionDetails.ticketIds = _ticketIds;
        transactionDetails.priceTotal = uint64(_priceTotal);
        transactionDetails.timeStamp = uint64(block.timestamp);
    }

    function getUserTransactionsDetails()
        external
        view
        returns (TransactionDetails[] memory transactionsDetails)
    {
        uint256 transactionAmount = userToTransactionAmount[msg.sender];
        transactionsDetails = new TransactionDetails[](transactionAmount);
        for (uint256 i; i < transactionAmount; ++i) {
            bytes32 transactionId = userToTransactionId[msg.sender][i + 1];
            transactionsDetails[i] = transactionIdToDetails[transactionId];
        }
        return transactionsDetails;
    }

    function getuserTransactions()
        external
        view
        returns (bytes32[] memory transactions)
    {
        uint256 transactionAmount = userToTransactionAmount[msg.sender];
        transactions = new bytes32[](transactionAmount);
        for (uint256 i; i < transactionAmount; ++i) {
            bytes32 transactionId = userToTransactionId[msg.sender][i + 1];
            transactions[i] = transactionId;
        }
    }
}
