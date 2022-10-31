// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./IRoles.sol";

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
        mapping(uint256 => CinemaDetails) cinemaToDetails;
    }

    IRoles public rolesInterface;
    uint64 public constant TICKET_PRICE_WEEKDAYS = 0.001 ether;
    uint64 public constant TICKET_PRICE_WEEKEND = 0.0012 ether;
    uint8 internal constant REGION_AMOUNT = 32;

    uint64 private unixTime;
    bool private isOpen;

    mapping(uint256 => RegionDetails) public regionToDetails;

    modifier isAdmin(uint256 _cinema) {
        rolesInterface.checkAdmin(_cinema, msg.sender);
        _;
    }

    function setInterface(address _rolesContractAddress) external {
        rolesInterface = IRoles(_rolesContractAddress);
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
            capacities[i] = cinemaDetails.studiosCapacities[i + 1];
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
        uint256 showTimesAmount = cinemaDetails.studioShowTimesAmount[_studio];
        showTimes = new uint256[](showTimesAmount);
        for (uint256 i; i < showTimesAmount; ++i) {
            showTimes[i] = cinemaDetails.studiosShowTimes[_studio][i + 1];
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

    function addRegionDetails(uint256 _region, bytes32 _name) external {
        RegionDetails storage details = regionToDetails[_region];
        details.cinemasAmount = 0;
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
        CinemaDetails storage cinemaDetails = regionDetails.cinemaToDetails[
            currentCinemasAmount + 1
        ];
        regionDetails.cinemasAmount = uint8(currentCinemasAmount + 1);
        regionDetails.cinemas[currentCinemasAmount + 1] = uint32(
            currentCinemasAmount + 1
        );

        for (uint256 i; i < _studiosAmount; ++i) {
            cinemaDetails.studiosCapacities[i + 1] = uint8(_studioCapacity[i]);
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
    ) external isAdmin(_cinema) {
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
    ) external {
        RegionDetails storage regionDetails = regionToDetails[_region];
        CinemaDetails storage cinemaDetails = regionDetails.cinemaToDetails[
            _cinema
        ];
        uint256 studioShowTimesAmount = cinemaDetails.studioShowTimesAmount[
            _studio
        ];
        uint256 index = studioShowTimesAmount + 1;
        for (uint256 i; i < _showTimes.length; ++i) {
            cinemaDetails.studiosShowTimes[_studio][index] = uint64(
                _showTimes[i]
            );
            index++;
        }
        cinemaDetails.studioShowTimesAmount[_studio] = uint8(
            studioShowTimesAmount + _showTimes.length
        );
    }

    function setUnixTime(uint256 _time) internal {
        unixTime = uint64(_time);
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
        capacity = cinemaDetails.studiosCapacities[_studio];
    }

    function addMoviesToCinema(
        uint256 _region,
        uint256 _cinema,
        uint256 _amount
    ) external {
        RegionDetails storage regionDetails = regionToDetails[_region];
        CinemaDetails storage cinemaDetails = regionDetails.cinemaToDetails[
            _cinema
        ];
        uint256 amount = cinemaDetails.moviesAmount;
        cinemaDetails.moviesAmount = uint8(amount + _amount);
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
}
