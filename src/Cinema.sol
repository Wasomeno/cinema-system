// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Cinema is Ownable {
    struct CinemaDetails {
        bytes32 name;
        uint8 studiosAmount;
        uint8 moviesAmount;
    }

    struct RegionDetails {
        bytes32 name;
        uint8 cinemasAmount;
    }

    uint64 public constant TICKET_PRICE_WEEKDAYS = 0.001 ether;
    uint64 public constant TICKET_PRICE_WEEKEND = 0.0012 ether;
    uint8 internal constant REGION_AMOUNT = 32;

    uint8 private showTimesAmount;
    uint64 private unixTime;
    bool private isOpen;

    mapping(uint256 => CinemaDetails) public cinemaToDetails;
    mapping(uint256 => RegionDetails) public regionToDetails;
    mapping(uint256 => mapping(uint256 => uint32)) public regionToCinemas;
    mapping(uint256 => mapping(uint256 => uint8))
        public cinemaToStudiosCapacities;
    mapping(uint256 => mapping(uint256 => uint8[])) public cinemaToStudiosTime;
    mapping(uint256 => uint256) public showTimes;

    function openCinema() external onlyOwner {
        isOpen = true;
        uint256 dailyTimeChange = unixTime + 24 hours;
        if (unixTime < block.timestamp) {
            setUnixTime(dailyTimeChange);
        }
    }

    function getCinemasDetails(uint256 _region)
        external
        view
        returns (CinemaDetails[] memory details)
    {
        uint256 cinemasAmount = regionToDetails[_region].cinemasAmount;
        details = new CinemaDetails[](cinemasAmount);
        for (uint256 i; i < cinemasAmount; ++i) {
            uint256 cinema = regionToCinemas[_region][i];
            details[i] = cinemaToDetails[cinema];
        }
    }

    function getCinemaDetails(uint256 _cinema)
        external
        view
        returns (CinemaDetails memory details)
    {
        details = cinemaToDetails[_cinema];
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
        uint256 _studioAmount,
        uint256[] calldata _studioCapacity
    ) external {
        RegionDetails storage details = regionToDetails[_region];
        uint256 currentCinemasAmount = details.cinemasAmount;
        for (uint256 i; i < _studioAmount; ++i) {
            cinemaToStudiosCapacities[currentCinemasAmount + 1][i + 1] = uint8(
                _studioCapacity[i]
            );
        }
        details.cinemasAmount = uint8(currentCinemasAmount + 1);
        regionToCinemas[_region][currentCinemasAmount + 1] = uint32(
            currentCinemasAmount + 1
        );
        cinemaToDetails[currentCinemasAmount + 1] = CinemaDetails(
            _name,
            uint8(_studioAmount),
            0
        );
    }

    function adddShowTimes(uint256[] calldata _times) external {
        uint256 currentAmount = showTimesAmount;
        for (uint256 i; i < _times.length; ++i) {
            showTimes[currentAmount + i] = _times[i];
        }
    }

    function setUnixTime(uint256 _time) internal onlyOwner {
        unixTime = uint64(_time);
    }

    function getRegionsDetails()
        external
        view
        returns (RegionDetails[] memory details)
    {
        uint256 amount = REGION_AMOUNT;
        details = new RegionDetails[](REGION_AMOUNT);
        for (uint256 i; i < amount; ++i) {
            details[i] = regionToDetails[i];
        }
    }

    function addMoviesToCinema(uint256 _cinema, uint256 _amount) external {
        CinemaDetails storage details = cinemaToDetails[_cinema];
        uint256 amount = details.moviesAmount;
        details.moviesAmount = uint8(amount + _amount);
    }
}
