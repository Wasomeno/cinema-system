// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRoles {
    function checkAdmin(
        uint256 _region,
        uint256 _cinema,
        address _admin
    ) external view returns (bool result);
}
