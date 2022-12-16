// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./IRoles.sol";
import "./IMovies.sol";

contract Cinema is Ownable {
    struct CinemaDetails {
        bytes32 name;
        uint8 studiosAmount;
        uint8 moviesAmount;
        uint8 showTimesAmount;
        mapping(uint256 => uint256) movies;
        mapping(uint256 => uint64) showTimes;
        mapping(uint256 => StudioDetails) studioToDetails;
    }

    struct StudioDetails {
        uint8 capacity;
        uint8 showtimesAmount;
        mapping(uint256 => uint64) showTimes;
        mapping(uint256 => uint64) showTimeToMovie;
    }

    struct RegionDetails {
        bytes32 name;
        uint8 cinemasAmount;
        mapping(uint256 => uint32) cinemas;
        mapping(uint256 => CinemaDetails) cinemaToDetails;
    }

    IRoles internal rolesInterface;
    IMovies internal movieInterface;

    uint64 public constant TICKET_PRICE_WEEKDAYS = 0.001 ether;
    uint64 public constant TICKET_PRICE_WEEKEND = 0.0012 ether;

    uint64 private unixTime;
    bool private isOpen;
    uint8 public regionsAmount;

    mapping(uint256 => RegionDetails) public regionToDetails;
    mapping(uint256 => uint256) public availableRegions;

    modifier checkCinemaDetails(
        uint256 _region,
        uint256 _cinema,
        uint256 _studio,
        uint256[] calldata _showTimes
    ) {
        bool isCinemaExist = checkCinemaInRegion(_region, _cinema);
        uint256[] memory studioShowTimes = getStudioShowTimes(
            _region,
            _cinema,
            _studio
        );
        for (uint256 i; i < _showTimes.length; ++i) {
            bool isShowTimeExist = checkShowTime(
                _region,
                _cinema,
                _showTimes[i]
            );
            require(isShowTimeExist, "Studio or Showtime not exist");
        }
        require(isCinemaExist, "Cinema or Region not exist");
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
        address _movieContractAddress
    ) external onlySuperAdmin {
        rolesInterface = IRoles(_rolesContractAddress);
        movieInterface = IMovies(_movieContractAddress);
    }

    function resetTime() external {
        isOpen = true;
        uint256 dailyTimeChange = unixTime + 24 hours;
        unixTime < block.timestamp
            ? setUnixTime(dailyTimeChange)
            : setUnixTime(unixTime);
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
        RegionDetails storage regionDetails = regionToDetails[_region];
        CinemaDetails storage cinemaDetails = regionDetails.cinemaToDetails[
            _cinema
        ];
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
        RegionDetails storage regionDetails = regionToDetails[_region];
        CinemaDetails storage cinemaDetails = regionDetails.cinemaToDetails[
            _cinema
        ];
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
        RegionDetails storage regionDetails = regionToDetails[_region];
        CinemaDetails storage cinemaDetails = regionDetails.cinemaToDetails[
            _cinema
        ];
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
        RegionDetails storage regionDetails = regionToDetails[_region];
        CinemaDetails storage cinemaDetails = regionDetails.cinemaToDetails[
            _cinema
        ];
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
        RegionDetails storage regionDetails = regionToDetails[_region];
        CinemaDetails storage cinemaDetails = regionDetails.cinemaToDetails[
            _cinema
        ];
        uint256 studiosAmount = cinemaDetails.studiosAmount;
        showTimes = new uint256[][](studiosAmount);
        for (uint256 i; i < studiosAmount; ++i) {
            showTimes[i] = getStudioShowTimes(_region, _cinema, i);
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
        isMoviesExists(_movies)
        checkCinemaDetails(_region, _cinema, _studio, _showTimes)
    {
        CinemaDetails storage cinemaDetails = regionToDetails[_region]
            .cinemaToDetails[_cinema];
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
        isMoviesExists(_movies)
        checkCinemaDetails(_region, _cinema, _studio, _showTimes)
    {
        CinemaDetails storage cinemaDetails = regionToDetails[_region]
            .cinemaToDetails[_cinema];
        StudioDetails storage studioDetails = cinemaDetails.studioToDetails[
            _studio
        ];
        for (uint256 i; i < _showTimes.length; ++i) {
            studioDetails.showTimeToMovie[_showTimes[i]] = uint64(_movies[i]);
        }
    }

    function addRegion(uint256 _region, bytes32 _name) external onlySuperAdmin {
        uint256 currentRegionAmount = regionsAmount;
        availableRegions[currentRegionAmount + 1] = _region;
        RegionDetails storage details = regionToDetails[_region];
        details.cinemasAmount = 0;
        details.name = _name;
        regionsAmount = uint8(currentRegionAmount + 1);
    }

    function addCinema(
        uint256 _region,
        bytes32 _name,
        uint256 _studiosAmount,
        uint256[] calldata _studioCapacity
    ) external onlySuperAdmin {
        RegionDetails storage regionDetails = regionToDetails[_region];
        uint256 currentCinemasAmount = regionToDetails[_region].cinemasAmount;
        CinemaDetails storage cinemaDetails = regionDetails.cinemaToDetails[
            currentCinemasAmount + 1
        ];
        regionDetails.cinemasAmount = uint8(currentCinemasAmount + 1);
        regionDetails.cinemas[currentCinemasAmount + 1] = uint32(
            currentCinemasAmount + 1
        );

        for (uint256 i; i < _studiosAmount; ++i) {
            StudioDetails storage studioDetails = cinemaDetails.studioToDetails[
                i + 1
            ];
            studioDetails.capacity = uint8(_studioCapacity[i]);
        }
        cinemaDetails.moviesAmount = 0;
        cinemaDetails.name = _name;
        cinemaDetails.studiosAmount = uint8(_studiosAmount);
        cinemaDetails.showTimesAmount = 0;
    }

    function addShowTime(
        uint256 _region,
        uint256 _cinema,
        uint256 _time
    ) external onlyCinemaAdmin(_region, _cinema) {
        RegionDetails storage regionDetails = regionToDetails[_region];
        CinemaDetails storage cinemaDetails = regionDetails.cinemaToDetails[
            _cinema
        ];
        uint256 currentShowTimesAmount = cinemaDetails.showTimesAmount;
        cinemaDetails.showTimes[currentShowTimesAmount + 1] = uint64(_time);
        cinemaDetails.showTimesAmount = uint8(currentShowTimesAmount + 1);
    }

    function addStudioShowTimes(
        uint256 _region,
        uint256 _cinema,
        uint256 _studio,
        uint256[] calldata _showTimes
    ) external onlyCinemaAdmin(_region, _cinema) {
        RegionDetails storage regionDetails = regionToDetails[_region];
        CinemaDetails storage cinemaDetails = regionDetails.cinemaToDetails[
            _cinema
        ];
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

    function getRegions() external view returns (uint256[] memory regions) {
        uint256 amount = regionsAmount;
        regions = new uint256[](amount);
        for (uint256 i; i < amount; ++i) {
            regions[i] = availableRegions[i + 1];
        }
    }

    function getRegionsDetails(uint256 _region)
        internal
        view
        returns (RegionDetails storage details)
    {
        details = regionToDetails[_region];
    }

    function getStudioCapacity(
        uint256 _region,
        uint256 _cinema,
        uint256 _studio
    ) external view returns (uint256 capacity) {
        RegionDetails storage regionDetails = regionToDetails[_region];
        CinemaDetails storage cinemaDetails = regionDetails.cinemaToDetails[
            _cinema
        ];
        capacity = cinemaDetails.studioToDetails[_studio].capacity;
    }

    function addMoviesToCinema(
        uint256 _region,
        uint256 _cinema,
        uint256 _amount
    ) external onlySuperAdmin {
        RegionDetails storage regionDetails = regionToDetails[_region];
        CinemaDetails storage cinemaDetails = regionDetails.cinemaToDetails[
            _cinema
        ];
        uint256 amount = cinemaDetails.moviesAmount;
        cinemaDetails.moviesAmount = uint8(amount + _amount);
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

    function checkCinemaInRegion(uint256 _region, uint256 _cinema)
        public
        view
        returns (bool result)
    {
        RegionDetails storage regionDetails = regionToDetails[_region];
        uint256 cinemasAmount = regionDetails.cinemasAmount;
        for (uint256 i; i < cinemasAmount; ++i) {
            uint256 cinema = regionDetails.cinemas[i + 1];
            if (cinema == _cinema) {
                result = true;
            }
        }
    }

    function getCinemaMoviesAmount(uint256 _region, uint256 _cinema)
        external
        view
        returns (uint256 amount)
    {
        RegionDetails storage regionDetails = regionToDetails[_region];
        CinemaDetails storage cinemaDetails = regionDetails.cinemaToDetails[
            _cinema
        ];

        amount = cinemaDetails.moviesAmount;
    }
}
