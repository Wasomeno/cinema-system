// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/Movies.sol";
import "../src/Cinema.sol";

contract MoviesTest is Test {
    Movies public moviesContract;
    Cinema public cinemaContract;
    bytes32[] public _titles;
    uint256[] public _durations;
    uint256[] public _studios;

    function moviesToAddSetup() public {
        for (uint256 i; i < 3; ++i) {
            _titles.push(keccak256("Ice Age"));
            _durations.push(2);
            _studios.push(i + 1);
        }
    }

    function setUp() public {
        moviesContract = new Movies();
        cinemaContract = new Cinema();
        moviesContract.setInterfaces(address(cinemaContract));
    }

    function testAddMovies() public {
        moviesToAddSetup();
        moviesContract.addMovies(_titles, _durations, _studios);
        console.log(moviesContract.getMovieDetails(1).duration);
    }

    function testAddMoviesToCinema() public {
        uint256[] memory moviesToAdd = new uint256[](3);
        for (uint256 i; i < 3; ++i) {
            moviesToAdd[i] = i + 1;
        }
        moviesContract.addMoviesToCinema(123, moviesToAdd);
        uint32[] memory movies = moviesContract.getMoviesInCinema(123);
        console.log(uint256(movies[0]));
    }
}
