// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../lib/forge-std/src/console.sol";
import "./ICinema.sol";

contract Movies {
    struct MovieDetails {
        bytes32 title;
        uint8 duration;
        uint8 studio;
    }

    ICinema public cinemaInterface;

    uint32 moviesTotal;
    mapping(uint256 => mapping(uint256 => uint32)) public cinemaToMovies;
    mapping(uint256 => MovieDetails) public movieToDetails;

    function setInterfaces(address _cinemaContractAddress) public {
        cinemaInterface = ICinema(_cinemaContractAddress);
    }

    function addMovies(
        bytes32[] calldata _titles,
        uint256[] calldata _durations,
        uint256[] calldata _studios
    ) external {
        uint256 _moviesTotal = moviesTotal;
        for (uint256 i; i < _titles.length; ++i) {
            _moviesTotal = _moviesTotal + 1;
            MovieDetails storage details = movieToDetails[_moviesTotal];
            details.title = _titles[i];
            details.duration = uint8(_durations[i]);
            details.studio = uint8(_studios[i]);
        }
        moviesTotal = uint32(_moviesTotal);
    }

    function addMoviesToCinema(uint256 _cinema, uint256[] calldata _movies)
        external
    {
        uint32[] memory currentMovies = getMoviesInCinema(_cinema);
        for (uint256 i; i < _movies.length; ++i) {
            cinemaToMovies[_cinema][currentMovies.length + i] = uint32(
                _movies[i]
            );
        }
        cinemaInterface.addMoviesToCinema(_cinema, _movies.length);
    }

    function getMovieDetails(uint256 _movieId)
        external
        view
        returns (MovieDetails memory details)
    {
        details = movieToDetails[_movieId];
    }

    function getMoviesInCinema(uint256 _cinema)
        public
        view
        returns (uint32[] memory movies)
    {
        uint256 moviesAmount = cinemaInterface
            .getCinemaDetails(_cinema)
            .moviesAmount;
        movies = new uint32[](moviesAmount);
        for (uint256 i; i < moviesAmount; ++i) {
            movies[i] = cinemaToMovies[_cinema][i];
        }
    }
}
