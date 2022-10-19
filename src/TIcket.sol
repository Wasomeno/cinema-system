// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/erc721a/contracts/extensions/ERC721ABurnable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Ticket is ERC721ABurnable, Ownable {
    struct TicketDetails {
        uint32 region;
        uint8 cinema;
        uint8 studio;
        uint32 movie;
        uint64 time;
    }

    uint64 public constant TICKET_PRICE_WEEKDAYS = 0.001 ether;
    uint64 public constant TICKET_PRICE_WEEKEND = 0.0012 ether;

    mapping(uint256 => mapping(uint256 => TicketDetails))
        public cinemaToTicketDetails;
    mapping(uint256 => uint256) public cinemaToTicketsSold;

    constructor() ERC721A("Cinema 21 Tickets", "C21") {}

    function mintTicket(
        uint256 _region,
        uint256 _cinema,
        uint256 _studio,
        uint256 _movie,
        uint256 _day,
        uint256 _showTime,
        uint256 _quantity
    ) external payable {
        uint256 price = getPrice(_day);
        require(msg.value == price, "Wrong eth value sent");
        uint256 ticketSold = cinemaToTicketsSold[_cinema];
        TicketDetails storage details = cinemaToTicketDetails[_cinema][
            ticketSold
        ];
        details.cinema = uint8(_cinema);
        details.movie = uint32(_movie);
        details.studio = uint8(_studio);
        details.region = uint32(_region);
        details.time = uint64(_showTime);
        _mint(msg.sender, _quantity);
    }

    function getPrice(uint256 _day) public pure returns (uint256 price) {
        if (_day > 5) {
            price = TICKET_PRICE_WEEKEND;
        } else {
            price = TICKET_PRICE_WEEKDAYS;
        }
    }

    function burnTicket() external {}

    receive() external payable {}
}
