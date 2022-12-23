// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/Cinema.sol";
import "../src/Ticket.sol";
import "../src/Roles.sol";
import "../src/Movies.sol";
import "../src/Region.sol";
import "../src/Transactions.sol";

contract CinemasTest is Test {
    Cinema public cinemaContract;
    Ticket public ticketContract;
    Roles public rolesContract;
    Movies public moviesContract;
    Region public regionContract;
    Transactions public transactionContract;

    uint256 CINEMA_GENERATED_AMOUNT = 3;

    uint256 DEFAULT_CINEMA_ID_VALUE = 1;
    string DEFAULT_CINEMA_NAME_VALUE = "Cinema";
    uint256 DEFAULT_CINEMA_STUDIO_AMOUNTS = 3;
    uint256[] DEFAULT_CINEMA_STUDIO_CAPACITY = [50, 60, 70];

    uint256 DEFAULT_SHOWTIME_VALUE = 3000;

    function setUp() public {
        cinemaContract = new Cinema();
        rolesContract = new Roles();
        moviesContract = new Movies();
        regionContract = new Region();
        cinemaContract.setInterface(
            address(rolesContract),
            address(moviesContract),
            address(regionContract)
        );
    }

    function generateCinemas()
        internal
        view
        returns (
            uint256[] memory ids,
            bytes32[] memory names,
            uint256[] memory studioAmounts,
            uint256[][] memory studioCapacities
        )
    {
        uint256 length = CINEMA_GENERATED_AMOUNT;
        ids = new uint256[](length);
        names = new bytes32[](length);
        studioAmounts = new uint256[](length);
        studioCapacities = new uint256[][](length);

        for (uint256 i; i < 3; ++i) {
            uint256 id = DEFAULT_CINEMA_ID_VALUE;
            bytes32 name = keccak256(abi.encode(DEFAULT_CINEMA_NAME_VALUE, id));
            uint256 studioAmount = DEFAULT_CINEMA_STUDIO_AMOUNTS;
            uint256[] memory studioCapacity = DEFAULT_CINEMA_STUDIO_CAPACITY;
            ids[i] = id;
            names[i] = name;
            studioAmounts[i] = studioAmount;
            studioCapacities[i] = DEFAULT_CINEMA_STUDIO_CAPACITY;
            id += 1;
        }
    }

    function generateShowTimes()
        internal
        view
        returns (uint256[] memory showTimes)
    {
        showTimes = new uint256[](3);
        uint256 showTimeValue = DEFAULT_SHOWTIME_VALUE;
        for (uint256 i; i < 3; ++i) {
            showTimes[i] = showTimeValue;
            showTimeValue += 1000;
        }
    }

    function generateMovies()
        public
        view
        returns (
            uint256[] memory ids,
            bytes32[] memory titles,
            uint256[] memory durations
        )
    {
        uint256 DEFAULT_MOVIE_ID = 1;
        string memory DEFAULT_MOVIE_TITLE = "Movie";
        uint256 DEFAULT_MOVIE_DURATION = 1200;
        ids = new uint256[](5);
        titles = new bytes32[](5);
        durations = new uint256[](5);
        for (uint256 i; i < 5; ++i) {
            titles[i] = keccak256(
                abi.encode(DEFAULT_MOVIE_TITLE, DEFAULT_MOVIE_ID)
            );
            durations[i] = DEFAULT_MOVIE_DURATION;
            DEFAULT_MOVIE_DURATION += 600;
            DEFAULT_MOVIE_ID += 1;
        }
    }

    function testAddCinema() public {
        bytes32 regionName = keccak256("Cilegon");
        regionContract.addRegion(1, regionName);
        (
            uint256[] memory ids,
            bytes32[] memory names,
            uint256[] memory studioAmounts,
            uint256[][] memory studioCapacities
        ) = generateCinemas();

        cinemaContract.addCinemas(
            1,
            ids,
            names,
            studioAmounts,
            studioCapacities
        );
        (bytes32 name, uint256 studiosAmount, , , , , ) = cinemaContract
            .getCinemaDetails(1, 1);
    }

    function testAddShowTimes() public {
        uint256[] memory showTimes = generateShowTimes();
        vm.prank(0xb0953E331CEB0f60E967CB64fA24e63c74bdC215);
        vm.mockCall(
            address(this),
            abi.encodeWithSelector(
                cinemaContract.addShowTimes.selector,
                1,
                1,
                showTimes
            ),
            abi.encode(false)
        );
        cinemaContract.addShowTimes(1, 1, showTimes);
        uint256[] memory timesAfter = cinemaContract.getCinemaShowTimes(1, 1);
        vm.clearMockedCalls();
        console.log(timesAfter[0]);
    }

    function testAddShowTimeToStudio() public {
        uint256[] memory showTimes = generateShowTimes();
        cinemaContract.addShowTimes(1, 1, showTimes);
        cinemaContract.addStudioShowTimes(1, 1, 1, showTimes);
        uint256[] memory showTimesAfter = cinemaContract.getStudioShowTimes(
            1,
            1,
            1
        );
    }

    function testAddMoviesToStudio() public {
        testAddCinema();
        testAddShowTimes();
        testAddShowTimeToStudio();
        uint256[] memory showTimes = generateShowTimes();
        (
            uint256[] memory movieIds,
            bytes32[] memory titles,
            uint256[] memory durations
        ) = generateMovies();
        moviesContract.addMovies(movieIds, titles, durations);
        cinemaContract.addMoviesToCinema(1, 1, movieIds);
        cinemaContract.addMoviesToStudio(movieIds, 1, 1, 1, showTimes);
    }

    function testMintTicket() public {
        uint256[] memory seats = new uint256[](2);
        seats[0] = 15;
        seats[1] = 16;
        ticketContract.mintTickets(3, 1, 1, 1, 5, 1, seats);
    }
}
