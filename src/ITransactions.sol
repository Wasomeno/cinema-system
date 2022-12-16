// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITransactions {
    function addNewTransaction(
        uint256 _region,
        uint256 _cinema,
        bytes32[] calldata _ticketIds,
        uint256 _priceTotal
    ) external;
}
