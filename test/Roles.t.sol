// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "../src/Roles.sol";
import "../src/Cinema.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";

contract RolesTest is Test {
    Roles rolesContract;
    Cinema cinemaContract;

    uint256 DEFAULT_SUPER_ADMIN_ADDRESS_VALUE = 481041;
    uint256 DEFAULT_CINEMA_ADMIN_ADDRESS_VALUE = 301415;

    function setUp() public {
        rolesContract = new Roles();
        cinemaContract = new Cinema();
        rolesContract.setInterface(address(cinemaContract));
    }

    function generateSuperAdminAddresses()
        internal
        view
        returns (address[] memory addresses)
    {
        addresses = new address[](3);
        uint256 defaultValue = DEFAULT_SUPER_ADMIN_ADDRESS_VALUE;
        for (uint256 i; i < 3; ++i) {
            address newAddress = address(uint160(defaultValue));
            addresses[i] = newAddress;
            defaultValue += 5;
        }
    }

    function generateCinemaAdminAddresses()
        internal
        view
        returns (address[] memory addresses)
    {
        addresses = new address[](3);
        uint256 defaultValue = DEFAULT_CINEMA_ADMIN_ADDRESS_VALUE;
        for (uint256 i; i < 3; ++i) {
            address newAddress = address(uint160(defaultValue));
            addresses[i] = newAddress;
            defaultValue += 5;
        }
    }

    function testAddSuperAdmins() public {
        address[] memory newAdmins = generateSuperAdminAddresses();
        rolesContract.addSuperAdmins(newAdmins);
        uint256 superAdminsAmount = rolesContract.superAdminsAmount();
        console.log(superAdminsAmount);
    }

    function testDeleteSuperAdmins() public {
        address[] memory newAdmins = generateSuperAdminAddresses();
        rolesContract.addSuperAdmins(newAdmins);
        rolesContract.deleteSuperAdmins(newAdmins);
        address superAdmin = rolesContract.superAdmins(0);
        console.log(superAdmin);
    }

    function testAddCinemaAdmins() public {
        address[] memory newAdmins = generateCinemaAdminAddresses();
        rolesContract.addCinemaAdmins(1, 1, newAdmins);
    }
}
