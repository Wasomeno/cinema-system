// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/Movies.sol";

contract MoviesTest is Test {
    Movies moviesContract;

    uint256 DEFAULT_MOVIE_ID = 1;
    string DEFAULT_MOVIE_TITLE = "Movie";
    uint256 DEFAULT_MOVIE_DURATION = 1200;

    function setUp() public {
        moviesContract = new Movies();
    }

    function generateMovies()
        internal
        view
        returns (
            uint256[] memory ids,
            bytes32[] memory titles,
            uint256[] memory durations
        )
    {
        uint256 id = DEFAULT_MOVIE_ID;
        string memory title = DEFAULT_MOVIE_TITLE;
        uint256 duration = DEFAULT_MOVIE_DURATION;
        ids = new uint256[](5);
        titles = new bytes32[](5);
        durations = new uint256[](5);
        for (uint256 i; i < 5; ++i) {
            titles[i] = keccak256(abi.encode(title, id));
            durations[i] = duration;
            duration += 600;
            id += 1;
        }
    }

    function testAddMovies() public {
        (
            uint256[] memory movieIds,
            bytes32[] memory titles,
            uint256[] memory durations
        ) = generateMovies();
        moviesContract.addMovies(movieIds, titles, durations);
    }

    function testDeleteMovies() public {
        (
            uint256[] memory movieIds,
            bytes32[] memory titles,
            uint256[] memory durations
        ) = generateMovies();
        moviesContract.addMovies(movieIds, titles, durations);
        moviesContract.deleteMovies(movieIds);
    }
}
