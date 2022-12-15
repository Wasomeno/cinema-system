// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IMovies {
    function isMovieExist(uint256 _movie) external view returns (bool result);

    function isMoviesExists(uint256[] calldata _movies)
        external
        view
        returns (bool[] memory results);
}
