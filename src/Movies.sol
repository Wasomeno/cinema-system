// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../lib/forge-std/src/console.sol";
import "./IMovies.sol";

contract Movies {
    struct MovieDetails {
        bytes32 title;
        uint64 duration;
    }
    uint32 public moviesTotal;
    mapping(uint256 => MovieDetails) public movieToDetails;
    mapping(uint256 => bool) public ExsistsMovies;

    function addMovies(
        bytes32[] calldata _titles,
        uint256[] calldata _durations
    ) external {
        uint256 total = moviesTotal;
        for (uint256 i; i < _titles.length; ++i) {
            total += 1;
            MovieDetails storage details = movieToDetails[total];
            details.duration = uint64(_durations[i]);
            details.title = _titles[i];
        }
        moviesTotal = uint32(total);
    }

    function getMovieDetails(uint256 _movieId)
        external
        view
        returns (MovieDetails memory details)
    {
        details = movieToDetails[_movieId];
    }

    function getMovies() external view returns (bytes32[] memory movies) {
        uint256 currentAmount = moviesTotal;
        movies = new bytes32[](currentAmount);
        for (uint256 i; i < currentAmount; ++i) {
            movies[i] = movieToDetails[i + 1].title;
        }
    }

    function isMovieExist(uint256 _movie) public view returns (bool result) {
        result = ExsistsMovies[_movie];
    }
}
