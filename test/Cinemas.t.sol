// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/Cinema.sol";

contract CinemasTest is Test {
    Cinema public cinemaContract;
    bytes32[] public _names;
    uint256[] public _studiosAmounts;
    uint256[] public _studiosCapacities;

    function cinemasToAdd() public {
        for (uint256 i; i < 3; ++i) {
            _names.push(keccak256(abi.encode("Ice Age ", i)));
            _studiosAmounts.push(3);
            _studiosCapacities.push(30 * (i + 1));
        }
    }

    function setUp() public {
        cinemaContract = new Cinema();
    }

    function testAddCinemas() public {
        cinemasToAdd();
        cinemaContract.addCinemas(
            10,
            _names,
            _studiosAmounts,
            _studiosCapacities
        );
        console.log(cinemaContract.getCinemaDetails(0).studiosAmount);
    }
}
