// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Cinema is Ownable {
    struct CinemaDetails {
        bytes32 name;
        uint8 studiosAmount;
        uint8 moviesAmount;
        uint8 showTimesAmount;
        mapping(uint256 => uint64) showTimes;
        mapping(uint256 => uint8) studioShowTimesAmount;
        mapping(uint256 => mapping(uint256 => uint64)) studiosShowTimes;
        mapping(uint256 => uint8) studiosCapacities;
    }

    struct RegionDetails {
        bytes32 name;
        uint8 cinemasAmount;
        mapping(uint256 => uint32) cinemas;
    }

    uint64 public constant TICKET_PRICE_WEEKDAYS = 0.001 ether;
    uint64 public constant TICKET_PRICE_WEEKEND = 0.0012 ether;
    uint8 internal constant REGION_AMOUNT = 32;

    uint64 private unixTime;
    bool private isOpen;

    mapping(uint256 => CinemaDetails) public cinemaToDetails;
    mapping(uint256 => RegionDetails) public regionToDetails;

    function resetTime() external onlyOwner {
        isOpen = true;
        uint256 dailyTimeChange = unixTime + 24 hours;
        unixTime < block.timestamp
            ? setUnixTime(dailyTimeChange)
            : setUnixTime(unixTime);
    }

    function getCinemaDetails(uint256 _cinema)
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
        CinemaDetails storage details = cinemaToDetails[_cinema];
        name = details.name;
        studiosAmount = details.studiosAmount;
        moviesAmount = details.moviesAmount;
        showTimesAmount = details.showTimesAmount;
        showTimes = getCinemaShowTimes(_cinema);
        studioShowTimes = getStudiosShowTimes(_cinema);
        studiosCapacities = getCinemaStudioCapacities(_cinema);
    }

    function getCinemaShowTimes(uint256 _cinema)
        public
        view
        returns (uint256[] memory showTimes)
    {
        CinemaDetails storage details = cinemaToDetails[_cinema];
        uint256 showTimesAmount = details.showTimesAmount;
        showTimes = new uint256[](showTimesAmount);
        for (uint256 i; i < showTimesAmount; ++i) {
            showTimes[i] = details.showTimes[i];
        }
    }

    function getCinemaStudioCapacities(uint256 _cinema)
        public
        view
        returns (uint256[] memory capacities)
    {
        CinemaDetails storage details = cinemaToDetails[_cinema];
        uint256 studiosAmount = details.studiosAmount;
        capacities = new uint256[](studiosAmount);
        for (uint256 i; i < studiosAmount; ++i) {
            capacities[i] = details.studiosCapacities[i];
        }
    }

    function getStudioShowTimes(uint256 _cinema, uint256 _studio)
        public
        view
        returns (uint256[] memory showTimes)
    {
        CinemaDetails storage details = cinemaToDetails[_cinema];
        uint256 showTimesAmount = details.studioShowTimesAmount[_studio];
        showTimes = new uint256[](showTimesAmount);
        for (uint256 i; i < showTimesAmount; ++i) {
            showTimes[i] = details.studiosShowTimes[_studio][i];
        }
    }

    function getStudiosShowTimes(uint256 _cinema)
        public
        view
        returns (uint256[][] memory showTimes)
    {
        CinemaDetails storage details = cinemaToDetails[_cinema];
        uint256 studiosAmount = details.studiosAmount;

        showTimes = new uint256[][](studiosAmount);
        for (uint256 i; i < studiosAmount; ++i) {
            showTimes[i] = getStudioShowTimes(_cinema, i);
        }
    }

    function addRegionDetails(
        uint256 _region,
        bytes32 _name,
        uint256 _cinemasAmount
    ) external {
        RegionDetails storage details = regionToDetails[_region];
        details.cinemasAmount = uint8(_cinemasAmount);
        details.name = _name;
    }

    function addCinema(
        uint256 _region,
        bytes32 _name,
        uint256 _studiosAmount,
        uint256[] calldata _studioCapacity
    ) external {
        RegionDetails storage regionDetails = regionToDetails[_region];
        uint256 currentCinemasAmount = regionDetails.cinemasAmount;
        CinemaDetails storage cinemaDetails = cinemaToDetails[
            currentCinemasAmount + 1
        ];
        for (uint256 i; i < _studiosAmount; ++i) {
            cinemaDetails.studiosCapacities[i] = uint8(_studioCapacity[i]);
        }
        regionDetails.cinemasAmount = uint8(currentCinemasAmount + 1);
        regionDetails.cinemas[currentCinemasAmount + 1] = uint32(
            currentCinemasAmount + 1
        );
        cinemaDetails.moviesAmount = 0;
        cinemaDetails.name = _name;
        cinemaDetails.studiosAmount = uint8(_studiosAmount);
        cinemaDetails.showTimesAmount = 0;
    }

    function adddShowTimes(uint256 _cinema, uint256[] calldata _times)
        external
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_cinema];
        uint256 currentShowTimesAmount = cinemaDetails.showTimesAmount;
        for (uint256 i; i < _times.length; ++i) {
            cinemaDetails.showTimes[currentShowTimesAmount] = uint64(_times[i]);
            currentShowTimesAmount++;
        }
        cinemaDetails.showTimesAmount = uint8(currentShowTimesAmount);
    }

    function updateStudiosShowTimes(
        uint256 _cinema,
        uint256[] calldata _studios,
        uint256[][] calldata _showTimes
    ) external {
        for (uint256 i; i < _studios.length; ++i) {
            addStudioShowTimes(_cinema, _studios[i], _showTimes[i]);
        }
    }

    function addStudioShowTimes(
        uint256 _cinema,
        uint256 _studio,
        uint256[] calldata _showTimes
    ) internal {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_cinema];
        uint256 studioShowTimesAmount = cinemaDetails.studioShowTimesAmount[
            _studio
        ];
        for (uint256 i; i < _showTimes.length; ++i) {
            cinemaDetails.studiosShowTimes[_studio][
                studioShowTimesAmount
            ] = uint64(_showTimes[i]);
            studioShowTimesAmount++;
        }
        cinemaDetails.studioShowTimesAmount[_studio] = uint8(
            studioShowTimesAmount
        );
    }

    function setUnixTime(uint256 _time) internal onlyOwner {
        unixTime = uint64(_time);
    }

    function getRegionsDetails(uint256 _region)
        internal
        view
        returns (RegionDetails storage details)
    {
        details = regionToDetails[_region];
    }

    function getStudioCapacity(uint256 _cinema, uint256 _studio)
        external
        view
        returns (uint256 capacity)
    {
        CinemaDetails storage cinemaDetails = cinemaToDetails[_cinema];
        capacity = cinemaDetails.studiosCapacities[_studio];
    }

    function addMoviesToCinema(uint256 _cinema, uint256 _amount) external {
        CinemaDetails storage details = cinemaToDetails[_cinema];
        uint256 amount = details.moviesAmount;
        details.moviesAmount = uint8(amount + _amount);
    }
}
