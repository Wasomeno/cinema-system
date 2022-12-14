// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./IRoles.sol";
import "./IMovies.sol";
import "./IRegion.sol";

contract Cinema is Ownable {
    struct CinemaDetails {
        uint16 cinemaId;
        bytes32 name;
        uint8 studiosAmount;
        uint8 moviesAmount;
        uint8 showTimesAmount;
        mapping(uint256 => uint256) movies;
        mapping(uint256 => uint64) showTimes;
        mapping(uint256 => StudioDetails) studioToDetails;
    }

    struct StudioDetails {
        uint8 studio;
        uint8 capacity;
        uint8 showtimesAmount;
        mapping(uint256 => uint64) showTimes;
        mapping(uint256 => uint64) showTimeToMovie;
    }

    IRoles internal rolesInterface;
    IMovies internal movieInterface;
    IRegion internal regionInterface;

    uint64 private unixTime;
    bool private isOpen;

    mapping(uint256 => mapping(uint256 => CinemaDetails))
        public cinemaToDetails;

    modifier isCinemaExist(uint256 _region, uint256 _cinema) {
        bool result = regionInterface.checkCinemaInRegion(_region, _cinema);
        require(result, "Cinema or Region not exist");
        _;
    }

    modifier isShowTimesExist(
        uint256 _region,
        uint256 _cinema,
        uint256[] calldata _showTimes
    ) {
        for (uint256 i; i < _showTimes.length; ++i) {
            bool result = checkShowTime(_region, _cinema, _showTimes[i]);
            require(result, "Studio or Showtime not exist");
        }
        _;
    }

    modifier isStudioShowTimesExist(
        uint256 _region,
        uint256 _cinema,
        uint256 _studio,
        uint256[] calldata _studioShowTimes
    ) {
        for (uint256 i; i < _studioShowTimes.length; ++i) {
            bool result = checkStudioShowTime(
                _region,
                _cinema,
                _studio,
                _studioShowTimes[i]
            );
            require(result, "Showtime does not exist");
        }
        _;
    }

    modifier isMoviesExists(uint256[] calldata _movies) {
        for (uint256 i; i < _movies.length; ++i) {
            uint256 movie = _movies[i];
            bool result = movieInterface.isMovieExist(movie);
            require(result, "Movie does not exist");
        }
        _;
    }

    modifier onlyCinemaAdmin(uint256 _region, uint256 _cinema) {
        bool result = rolesInterface.isCinemaAdmin(
            _region,
            _cinema,
            msg.sender
        );
        require(result, "You're not a cinema admin");
        _;
    }

    modifier onlySuperAdmin() {
        bool result = rolesInterface.isSuperAdmin();
        require(result, "You're not a super admin");
        _;
    }

    function setInterface(
        address _rolesContractAddress,
        address _movieContractAddress,
        address _regionContractAddress
    ) external onlyOwner {
        rolesInterface = IRoles(_rolesContractAddress);
        movieInterface = IMovies(_movieContractAddress);
        regionInterface = IRegion(_regionContractAddress);
    }

    function getCinemaDetails(uint256 _region, uint256 _cinema)
        external
        view
        returns (
            bytes32 name,
            uint256 studiosAmount,
            uint256 moviesAmount,
            uint256 showTimesAmount,
            uint256[] memory showTimes,
            uint256[][] memory studioShowTimes,
            uint256[] memory studiosCapacities
        )
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        name = cinemaDetails.name;
        studiosAmount = cinemaDetails.studiosAmount;
        moviesAmount = cinemaDetails.moviesAmount;
        showTimesAmount = cinemaDetails.showTimesAmount;
        showTimes = getCinemaShowTimes(_region, _cinema);
        studioShowTimes = getStudiosShowTimes(_region, _cinema);
        studiosCapacities = getCinemaStudioCapacities(_region, _cinema);
    }

    function getCinemaShowTimes(uint256 _region, uint256 _cinema)
        public
        view
        returns (uint256[] memory showTimes)
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        uint256 showTimesAmount = cinemaDetails.showTimesAmount;
        showTimes = new uint256[](showTimesAmount);
        for (uint256 i; i < showTimesAmount; ++i) {
            showTimes[i] = cinemaDetails.showTimes[i + 1];
        }
    }

    function getCinemaStudioCapacities(uint256 _region, uint256 _cinema)
        public
        view
        returns (uint256[] memory capacities)
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        uint256 studiosAmount = cinemaDetails.studiosAmount;
        capacities = new uint256[](studiosAmount);
        for (uint256 i; i < studiosAmount; ++i) {
            StudioDetails storage studioDetails = cinemaDetails.studioToDetails[
                i + 1
            ];
            capacities[i] = studioDetails.capacity;
        }
    }

    function getStudioShowTimes(
        uint256 _region,
        uint256 _cinema,
        uint256 _studio
    ) public view returns (uint256[] memory showTimes) {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        StudioDetails storage studioDetails = cinemaDetails.studioToDetails[
            _studio
        ];
        uint256 showTimesAmount = studioDetails.showtimesAmount;
        showTimes = new uint256[](showTimesAmount);
        for (uint256 i; i < showTimesAmount; ++i) {
            uint256 showTime = studioDetails.showTimes[i + 1];
            showTimes[i] = showTime;
        }
    }

    function getStudiosShowTimes(uint256 _region, uint256 _cinema)
        public
        view
        returns (uint256[][] memory showTimes)
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        uint256 studiosAmount = cinemaDetails.studiosAmount;
        showTimes = new uint256[][](studiosAmount);
        for (uint256 i; i < studiosAmount; ++i) {
            showTimes[i] = getStudioShowTimes(_region, _cinema, i + 1);
        }
    }

    function addMoviesToStudio(
        uint256[] calldata _movies,
        uint256 _region,
        uint256 _cinema,
        uint256 _studio,
        uint256[] calldata _showTimes
    )
        external
        onlyCinemaAdmin(_region, _cinema)
        isCinemaExist(_region, _cinema)
        isStudioShowTimesExist(_region, _cinema, _studio, _showTimes)
        isMoviesExists(_movies)
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        StudioDetails storage studioDetails = cinemaDetails.studioToDetails[
            _studio
        ];
        for (uint256 i; i < _showTimes.length; ++i) {
            uint256 movie = studioDetails.showTimeToMovie[_showTimes[i]];
            require(movie == 0, "Movie already exist in this showtime");
            studioDetails.showTimeToMovie[_showTimes[i]] = uint64(_movies[i]);
        }
    }

    function updateMoviesToStudio(
        uint256[] calldata _movies,
        uint256 _region,
        uint256 _cinema,
        uint256 _studio,
        uint256[] calldata _showTimes
    )
        external
        onlyCinemaAdmin(_region, _cinema)
        isCinemaExist(_region, _cinema)
        isStudioShowTimesExist(_region, _cinema, _studio, _showTimes)
        isMoviesExists(_movies)
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        StudioDetails storage studioDetails = cinemaDetails.studioToDetails[
            _studio
        ];
        for (uint256 i; i < _showTimes.length; ++i) {
            studioDetails.showTimeToMovie[_showTimes[i]] = uint64(_movies[i]);
        }
    }

    function deleteMoviesInStudio(
        uint256 _region,
        uint256 _cinema,
        uint256 _studio,
        uint256[] calldata _showTimes
    )
        external
        onlyCinemaAdmin(_region, _cinema)
        isCinemaExist(_region, _cinema)
        isStudioShowTimesExist(_region, _cinema, _studio, _showTimes)
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        StudioDetails storage studioDetails = cinemaDetails.studioToDetails[
            _studio
        ];
        for (uint256 i; i < _showTimes.length; ++i) {
            delete studioDetails.showTimeToMovie[_showTimes[i]];
        }
    }

    function addCinemas(
        uint256 _region,
        uint256[] calldata _cinemaIds,
        bytes32[] calldata _names,
        uint256[] calldata _studiosAmounts,
        uint256[][] calldata _studioCapacities
    ) external onlySuperAdmin {
        for (uint256 i; i < _cinemaIds.length; ++i) {
            CinemaDetails storage cinemaDetails = cinemaToDetails[_region][
                _cinemaIds[i]
            ];
            for (uint256 j; j < _studiosAmounts[i]; ++j) {
                StudioDetails storage studioDetails = cinemaDetails
                    .studioToDetails[j + 1];
                studioDetails.capacity = uint8(_studioCapacities[i][j]);
            }
            cinemaDetails.moviesAmount = 0;
            cinemaDetails.name = _names[i];
            cinemaDetails.studiosAmount = uint8(_studiosAmounts[i]);
            cinemaDetails.showTimesAmount = 0;
        }
        regionInterface.addCinemasInRegion(_region, _cinemaIds);
    }

    function deleteCinemas(uint256 _region, uint256[] calldata _cinemaIds)
        external
        onlySuperAdmin
    {
        for (uint256 i; i < _cinemaIds.length; ++i) {
            delete cinemaToDetails[_region][_cinemaIds[i]];
        }
        regionInterface.deleteCinemasInRegion(_region, _cinemaIds);
    }

    function addShowTimes(
        uint256 _region,
        uint256 _cinema,
        uint256[] calldata _showTimes
    )
        external
        onlyCinemaAdmin(_region, _cinema)
        isCinemaExist(_region, _cinema)
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        uint256 currentShowTimesAmount = cinemaDetails.showTimesAmount;
        for (uint256 i; i < _showTimes.length; ++i) {
            bool isShowTimeExist = checkShowTime(
                _region,
                _cinema,
                _showTimes[i]
            );
            require(!isShowTimeExist, "Show time already exist");
            currentShowTimesAmount += 1;
            cinemaDetails.showTimes[currentShowTimesAmount] = uint64(
                _showTimes[i]
            );
        }
        cinemaDetails.showTimesAmount = uint8(currentShowTimesAmount);
    }

    function deleteShowTime(
        uint256 _region,
        uint256 _cinema,
        uint256 _showTime
    )
        external
        onlyCinemaAdmin(_region, _cinema)
        isCinemaExist(_region, _cinema)
    {
        bool isShowTimeExist = checkShowTime(_region, _cinema, _showTime);
        require(isShowTimeExist, "Show time does not exist");
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        uint256 currentShowTimesAmount = cinemaDetails.showTimesAmount;
        uint256 showTimeKey = getShowTimeKey(_region, _cinema, _showTime);
        uint256 showTimeLast = cinemaDetails.showTimes[
            currentShowTimesAmount - 1
        ];
        cinemaDetails.showTimes[showTimeKey] = uint64(showTimeLast);
        delete cinemaDetails.showTimes[currentShowTimesAmount - 1];
        cinemaDetails.showTimesAmount = uint8(currentShowTimesAmount - 1);
    }

    function getShowTimeKey(
        uint256 _region,
        uint256 _cinema,
        uint256 _time
    ) internal view returns (uint256 key) {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        uint256 currentShowTimesAmount = cinemaDetails.showTimesAmount;
        for (uint256 i; i < currentShowTimesAmount; ++i) {
            uint256 showTime = cinemaDetails.showTimes[i];
            if (showTime == _time) {
                key = i;
            }
        }
    }

    function addStudioShowTimes(
        uint256 _region,
        uint256 _cinema,
        uint256 _studio,
        uint256[] calldata _showTimes
    )
        external
        onlyCinemaAdmin(_region, _cinema)
        isCinemaExist(_region, _cinema)
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        StudioDetails storage studioDetails = cinemaDetails.studioToDetails[
            _studio
        ];
        uint256 studioShowTimesAmount = studioDetails.showtimesAmount;
        uint256 index = studioShowTimesAmount + 1;
        for (uint256 i; i < _showTimes.length; ++i) {
            studioDetails.showTimes[index] = uint64(_showTimes[i]);
            index++;
        }
        studioDetails.showtimesAmount = uint8(
            studioShowTimesAmount + _showTimes.length
        );
    }

    function setUnixTime(uint256 _time) internal {
        unixTime = uint64(_time);
    }

    function getStudioCapacity(
        uint256 _region,
        uint256 _cinema,
        uint256 _studio
    ) external view returns (uint256 capacity) {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        capacity = cinemaDetails.studioToDetails[_studio].capacity;
    }

    function addMoviesToCinema(
        uint256 _region,
        uint256 _cinema,
        uint256[] calldata _movies
    )
        external
        onlySuperAdmin
        isCinemaExist(_region, _cinema)
        isMoviesExists(_movies)
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        uint256 cinemaMoviesAmount = cinemaDetails.moviesAmount;
        for (uint256 i; i < _movies.length; ++i) {
            cinemaMoviesAmount += 1;
            cinemaDetails.movies[cinemaMoviesAmount] = _movies[i];
        }
        cinemaDetails.moviesAmount = uint8(cinemaMoviesAmount);
    }

    function deleteMoviesInCinema(
        uint256 _region,
        uint256 _cinema,
        uint256[] calldata _movies
    )
        external
        onlyCinemaAdmin(_region, _cinema)
        isCinemaExist(_region, _cinema)
        isMoviesExists(_movies)
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        uint256 currentMoviesAmount = cinemaDetails.moviesAmount;
        uint256[] memory movieKeys = getMovieKeys(_region, _cinema, _movies);
        for (uint256 i; i < movieKeys.length; ++i) {
            currentMoviesAmount -= 1;
            uint256 movieInLastKey = cinemaDetails.movies[currentMoviesAmount];
            cinemaDetails.movies[movieKeys[i]] = movieInLastKey;
            delete cinemaDetails.movies[currentMoviesAmount];
        }
    }

    function getMovieKeys(
        uint256 _region,
        uint256 _cinema,
        uint256[] calldata _movies
    ) internal view returns (uint256[] memory keys) {
        keys = new uint256[](_movies.length);
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        uint256 currentMoviesAmount = cinemaDetails.moviesAmount;
        for (uint256 i; i < currentMoviesAmount; ++i) {
            uint256 movie = cinemaDetails.movies[i];
            if (movie == _movies[i]) {
                keys[i] = i;
            }
        }
    }

    function checkShowTime(
        uint256 _region,
        uint256 _cinema,
        uint256 _showTime
    ) public view returns (bool result) {
        uint256[] memory cinemaShowTimes = getCinemaShowTimes(_region, _cinema);
        for (uint256 i; i < cinemaShowTimes.length; ++i) {
            uint256 cinemaShowTime = cinemaShowTimes[i];
            if (_showTime == cinemaShowTime) {
                result = true;
            }
        }
    }

    function checkStudioShowTime(
        uint256 _region,
        uint256 _cinema,
        uint256 _studio,
        uint256 _showTime
    ) public view returns (bool result) {
        uint256[] memory studioShowTimes = getStudioShowTimes(
            _region,
            _cinema,
            _studio
        );
        for (uint256 i; i < studioShowTimes.length; ++i) {
            uint256 studioShowTime = studioShowTimes[i];
            if (studioShowTime == _showTime) {
                result = true;
            }
        }
    }

    function getCinemaMoviesAmount(uint256 _region, uint256 _cinema)
        external
        view
        returns (uint256 amount)
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];

        amount = cinemaDetails.moviesAmount;
    }

    function getMoviesInRegion(uint256 _region)
        external
        view
        returns (uint256[][] memory moviesInRegion)
    {
        uint256[] memory cinemasInRegion = regionInterface.getCinemasInRegion(
            _region
        );
        moviesInRegion = new uint256[][](cinemasInRegion.length);
        for (uint256 i; i < cinemasInRegion.length; ++i) {
            uint256 cinema = cinemasInRegion[i];
            uint256[] memory movies = getCinemaMovies(_region, cinema);
            moviesInRegion[i] = movies;
        }
    }

    function getMovieShowTimesInRegion(uint256 _region, uint256 _movie)
        external
        view
        returns (uint256[] memory cinemas, uint256[][][] memory movieShowTimes)
    {
        uint256[] memory cinemasInRegion = regionInterface.getCinemasInRegion(
            _region
        );
        cinemas = new uint256[](cinemasInRegion.length);
        movieShowTimes = new uint256[][][](cinemasInRegion.length);
        for (uint256 i; i < cinemasInRegion.length; ++i) {
            uint256 cinema = cinemasInRegion[i];
            cinemas[i] = cinema;
            // movieShowTimes[i] = getMovieShowTimesInCinema(
            //     _region,
            //     cinema,
            //     _movie
            // );
        }
    }

    function getMovieShowTimesInCinema(
        uint256 _region,
        uint256 _cinema,
        uint256 _movie
    ) public view returns (uint256[][] memory movieShowTimes) {
        uint256[] memory showTimes = getCinemaShowTimes(_region, _cinema);
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        uint256 studioAmount = cinemaDetails.studiosAmount;
        movieShowTimes = new uint256[][](showTimes.length);
        for (uint256 i; i < studioAmount; ++i) {
            uint256[] memory showtimes = getMovieShowTimesInStudio(
                _region,
                _cinema,
                _movie,
                i + 1
            );
            movieShowTimes[i] = showtimes;
        }
    }

    function getMovieShowTimesInStudio(
        uint256 _region,
        uint256 _cinema,
        uint256 _movie,
        uint256 _studio
    ) public view returns (uint256[] memory movieShowTimes) {
        uint256 searchIndex;
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        StudioDetails storage studioDetails = cinemaDetails.studioToDetails[
            _studio
        ];
        uint256 showtimesAmount = studioDetails.showtimesAmount;
        for (uint256 i; i < showtimesAmount; ++i) {
            uint256 showtime = studioDetails.showTimes[i];
            uint256 movie = studioDetails.showTimeToMovie[showtime];
            if (movie == _movie) {
                movieShowTimes = new uint256[](searchIndex + 1);
                movieShowTimes[searchIndex] = showtime;
                searchIndex += 1;
            }
        }
    }

    function getMoviesInStudio(
        uint256 _region,
        uint256 _cinema,
        uint256 _studio
    ) public view returns (uint256[] memory moviesInStudio) {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        StudioDetails storage studioDetails = cinemaDetails.studioToDetails[
            _studio
        ];
        uint256[] memory studioShowTimes = getStudioShowTimes(
            _region,
            _cinema,
            _studio
        );
        moviesInStudio = new uint256[](studioShowTimes.length);
        for (uint256 i; i < studioShowTimes.length; ++i) {
            uint256 showTime = studioShowTimes[i];
            uint256 movie = studioDetails.showTimeToMovie[showTime];
            moviesInStudio[i] = movie;
        }
    }

    function getCinemaMovies(uint256 _region, uint256 _cinema)
        public
        view
        returns (uint256[] memory movies)
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_region][_cinema];
        uint256 moviesAmount = cinemaDetails.moviesAmount;
        movies = new uint256[](moviesAmount);
        for (uint256 i; i < moviesAmount; ++i) {
            uint256 movie = cinemaDetails.movies[i + 1];
            movies[i] = movie;
        }
    }
}
