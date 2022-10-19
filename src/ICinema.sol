// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ICinema {
    struct CinemaDetails {
        bytes32 name;
        uint8 studiosAmount;
        uint8 moviesAmount;
    }

    function getCinemaDetails(uint256 _cinema)
        external
        view
        returns (CinemaDetails memory details);

    function addMoviesToCinema(uint256 _cinema, uint256 _amount) external;

    function getStudioCapacity(uint256 _cinema, uint256 _studio)
        external
        view
        returns (uint256 capacity);
}
