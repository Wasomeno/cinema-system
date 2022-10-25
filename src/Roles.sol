// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ICinema.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Roles is Ownable {
    struct UserHistory {
        uint32 ticket;
        uint64 timeStamp;
    }

    struct AdminDetails {
        uint8 region;
        uint32 cinema;
    }

    ICinema public cinemaInterface;

    mapping(address => uint256) public userHistoryAmount;
    mapping(address => mapping(uint256 => UserHistory)) public userToHistory;
    mapping(uint256 => mapping(address => bool)) public cinemaAdmins;
    mapping(uint256 => uint256) public cinemaAdminsAmount;
    mapping(address => AdminDetails) public adminToDetails;

    modifier isCinemaExist(uint256 _cinema, uint256 _region) {
        bool result = cinemaInterface.checkCinemaInRegion(_region, _cinema);
        require(result, "cinema not exist");
        _;
    }

    function setInterface(address _cinemaContractAddress) external {
        cinemaInterface = ICinema(_cinemaContractAddress);
    }

    function addUserHistory(address _user, uint256 _ticket) external {
        uint256 currentAmount = userHistoryAmount[_user];
        UserHistory storage userHistory = userToHistory[_user][
            currentAmount + 1
        ];
        userHistory.ticket = uint32(_ticket);
        userHistory.timeStamp = uint64(block.timestamp);
    }

    function addAdminsToCinema(
        uint256 _region,
        uint256 _cinema,
        address[] calldata _newAdmins
    ) external onlyOwner isCinemaExist(_cinema, _region) {
        uint256 currentAmount = cinemaAdminsAmount[_cinema];
        for (uint256 i; i < _newAdmins.length; ++i) {
            address newAdmin = _newAdmins[i];
            cinemaAdmins[_cinema][newAdmin] = true;
            adminToDetails[newAdmin] = AdminDetails(
                uint8(_region),
                uint32(_cinema)
            );
        }
        cinemaAdminsAmount[_cinema] = currentAmount + _newAdmins.length;
    }

    function checkAdmin(uint256 _cinema, address _admin)
        external
        view
        returns (bool result)
    {
        result = cinemaAdmins[_cinema][_admin];
    }
}
