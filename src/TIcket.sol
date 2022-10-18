// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/erc721a/contracts/extensions/ERC721ABurnable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Ticket is ERC721ABurnable, Ownable {
    struct TicketDetails {
        uint256 region;
        uint32 cinema;
        uint8 studio;
        uint32 movie;
        uint64 time;
    }

    uint64 public constant TICKET_PRICE_WEEKDAYS = 0.001 ether;
    uint64 public constant TICKET_PRICE_WEEKEND = 0.0012 ether;

    constructor() ERC721A("Cinema 21", "C21") {}

    function mintTicket() external {}

    function burnTicket() external {}
}
