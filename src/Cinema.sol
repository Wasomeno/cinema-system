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

    struct TicketDetails {
        uint256 region;
        uint32 cinema;
        uint8 studio;
        uint32 movie;
        uint64 time;
    }

    uint64 public constant TICKET_PRICE_WEEKDAYS = 0.001 ether;
    uint64 public constant TICKET_PRICE_WEEKEND = 0.0012 ether;
    uint8 internal constant REGION_AMOUNT = 32;

    mapping(uint256 => CinemaDetails) public cinemaToDetails;
    mapping(uint256 => RegionDetails) public regionToDetails;
    mapping(uint256 => mapping(uint256 => uint32)) public regionToCinemas;
    mapping(uint256 => mapping(uint256 => uint8)) public cinemaToStudioCap;

    function mintTicket() external {}

    function burnTicket() external {}

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

    function addCinemas(
        uint256 _region,
        bytes32[] calldata _names,
        uint256[] calldata _studiosAmounts,
        uint256[] calldata _studiosCapacity
    ) external {
        RegionDetails storage details = regionToDetails[_region];
        uint256 currentCinemasAmount = details.cinemasAmount;
        details.cinemasAmount = uint8(currentCinemasAmount + _names.length);
        for (uint256 i; i < _names.length; ++i) {
            regionToCinemas[_region][currentCinemasAmount + i] = uint32(
                currentCinemasAmount + 1
            );
            cinemaToDetails[currentCinemasAmount + i] = CinemaDetails(
                _names[i],
                uint8(_studiosAmounts[i]),
                0
            );
            cinemaToStudioCap[currentCinemasAmount + i][i] = uint8(
                _studiosCapacity[i]
            );
        }
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
