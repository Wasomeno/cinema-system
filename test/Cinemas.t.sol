// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/Cinema.sol";
import "../src/Ticket.sol";

contract CinemasTest is Test {
    Cinema public cinemaContract;
    Ticket public ticketContract;

    function setUp() public {
        cinemaContract = new Cinema();
        ticketContract = new Ticket();
        ticketContract.setInterfaces(address(cinemaContract));
    }

    function testAddRegion() public {
        bytes32 name = keccak256("Cilegon");
        cinemaContract.addRegionDetails(1, name, 5);
    }

    function testAddCinema() public {
        bytes32 _name = keccak256(abi.encode("Cilegon"));
        uint256 _studioAmount = 3;
        uint256[] memory _studiosCapacities = new uint256[](3);
        _studiosCapacities[0] = uint256(60);
        _studiosCapacities[1] = uint256(70);
        _studiosCapacities[2] = uint256(80);
        cinemaContract.addCinema(10, _name, _studioAmount, _studiosCapacities);
        (bytes32 name, uint256 studiosAmount, , , , , ) = cinemaContract
            .getCinemaDetails(1);
        console.log(studiosAmount);
    }

    function testAddShowTimes() public {
        uint256[] memory times = new uint256[](4);
        times[0] = uint256(10 hours);
        times[1] = uint256(12 hours);
        times[2] = uint256(16 hours);
        times[3] = uint256(18 hours);
        cinemaContract.adddShowTimes(1, times);
        uint256[] memory timesAfter = cinemaContract.getCinemaShowTimes(1);
        console.log(timesAfter[0]);
        console.log(timesAfter[1]);
        console.log(timesAfter[2]);
    }

    function testPairedStudiosWithShowTimes() public {
        uint256[] memory studios = new uint256[](3);
        studios[0] = uint256(0);
        studios[1] = uint256(1);
        studios[2] = uint256(2);
        uint256[][] memory showTimes = new uint256[][](3);
        showTimes[0] = studios;
        showTimes[1] = studios;
        showTimes[2] = studios;
        cinemaContract.updateStudiosShowTimes(1, studios, showTimes);
        uint256[] memory showTimesAfter = cinemaContract.getStudioShowTimes(
            1,
            0
        );
        console.log(showTimesAfter[0]);
    }

    function testMintTicket() public {
        uint256[] memory seats = new uint256[](2);
        seats[0] = 15;
        seats[1] = 16;
        ticketContract.mintTicket(10, 1, 1, 1, 5, 1, seats);
    }
}
