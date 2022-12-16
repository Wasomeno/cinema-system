// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/erc721a/contracts/extensions/ERC721ABurnable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./ICinema.sol";

contract Ticket is ERC721ABurnable, Ownable {
    struct TicketDetails {
        uint32 region;
        uint8 cinema;
        uint8 studio;
        uint32 movie;
        uint64 time;
        uint256 day;
        uint8 seatNumber;
    }

    ICinema public cinemaInterface;
    uint64 public constant TICKET_PRICE_WEEKDAYS = 0.001 ether;
    uint64 public constant TICKET_PRICE_WEEKEND = 0.0012 ether;

    mapping(bytes32 => TicketDetails) public ticketToDetails;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)))))
        public seatStatus;

    constructor() ERC721A("Cinema 21 Tickets", "C21") {}

    modifier seatsCheck(
        uint256 _region,
        uint256 _cinema,
        uint256 _studio,
        uint256 _showTime,
        uint256[] calldata _seats
    ) {
        for (uint256 i; i < _seats.length; ++i) {
            bool status = seatStatus[_region][_cinema][_studio][_showTime][
                _seats[i]
            ];
            require(!status, "taken");
        }
        _;
    }

    function setInterfaces(address _cinemaContract) external onlyOwner {
        cinemaInterface = ICinema(_cinemaContract);
    }

    function mintTickets(
        uint256 _day,
        uint256 _region,
        uint256 _cinema,
        uint256 _studio,
        uint256 _showTime,
        uint256 _movie,
        uint256[] calldata _seatNumbers
    )
        external
        payable
        seatsCheck(_region, _cinema, _studio, _showTime, _seatNumbers)
    {
        uint256 price = getPrice(_day);
        // require(
        //     msg.value == price * _seatNumbers.length,
        //     "Wrong eth value sent"
        // );
        for (uint256 i; i < _seatNumbers.length; ++i) {
            mintTicket(
                _region,
                _cinema,
                _studio,
                _showTime,
                _movie,
                _seatNumbers[i]
            );
        }
    }

    function mintTicket(
        uint256 _region,
        uint256 _cinema,
        uint256 _studio,
        uint256 _showTime,
        uint256 _movie,
        uint256 _seatNumber
    ) internal {
        bytes32 ticketId = keccak256(
            abi.encode(_nextTokenId(), _region, _cinema, msg.sender)
        );
        TicketDetails storage details = ticketToDetails[ticketId];
        details.cinema = uint8(_cinema);
        details.movie = uint32(_movie);
        details.studio = uint8(_studio);
        details.region = uint32(_region);
        details.time = uint64(_showTime);
        seatStatus[_region][_cinema][_studio][_showTime][_seatNumber] = true;
        _mint(msg.sender, 1);
    }

    function getPrice(uint256 _day) public pure returns (uint256 price) {
        if (_day > 5) {
            price = TICKET_PRICE_WEEKEND;
        } else {
            price = TICKET_PRICE_WEEKDAYS;
        }
    }

    function getAvailableSeats(
        uint256 _region,
        uint256 _cinema,
        uint256 _studio,
        uint256 _showTime
    ) public view returns (uint256[] memory seats) {
        uint256 seatsIndex = 0;
        uint256 seatsAmount = cinemaInterface.getStudioCapacity(
            _region,
            _cinema,
            _studio
        );
        seats = new uint256[](seatsAmount);
        for (uint256 i; i < seatsAmount; ++i) {
            bool status = seatStatus[_region][_cinema][_studio][_showTime][
                i + 1
            ];
            if (status != true) {
                seats[seatsIndex] = i + 1;
                seatsIndex++;
            }
        }
    }

    function burnTicket() external {}

    receive() external payable {}
}
