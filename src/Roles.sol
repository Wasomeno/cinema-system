// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ICinema.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Roles is Ownable {
    struct CinemaAdminsDetails {
        uint32 cinemaAdminsAmount;
        mapping(uint256 => address) cinemaAdmins;
        mapping(address => bool) cinemaAdminStatus;
        mapping(address => AdminDetails) adminDetails;
    }

    struct UserDetails {
        mapping(uint256 => mapping(uint256 => uint256)) transactionAmount;
        mapping(uint256 => mapping(uint256 => mapping(uint256 => bytes32))) transactionDetails;
    }

    struct AdminDetails {
        uint8 region;
        uint32 cinema;
    }

    ICinema public cinemaInterface;
    uint32 public superAdminsAmount;

    mapping(uint256 => mapping(uint256 => CinemaAdminsDetails))
        public cinemaAdminsDetails;
    mapping(address => UserDetails) internal userToDetails;
    mapping(address => bool) public superAdminStatus;
    mapping(uint256 => address) public superAdmins;

    constructor() {
        address[] memory newSuperAdmins = new address[](1);
        newSuperAdmins[0] = msg.sender;
        addSuperAdmins(newSuperAdmins);
    }

    modifier isAdminExists(
        address[] calldata _newAdmins,
        uint256 _region,
        uint256 _cinema
    ) {
        CinemaAdminsDetails storage details = cinemaAdminsDetails[_region][
            _cinema
        ];
        for (uint256 i; i < _newAdmins.length; ++i) {
            bool status = details.cinemaAdminStatus[_newAdmins[i]];
            require(!status, "Address already an admin");
        }
        _;
    }

    modifier onlySuperAdmin() {
        bool status = superAdminStatus[msg.sender];
        require(status, "You're not a super admin");
        _;
    }

    modifier isCinemaExist(uint256 _cinema, uint256 _region) {
        bool result = cinemaInterface.checkCinemaInRegion(_region, _cinema);
        require(result, "cinema not exist");
        _;
    }

    function setInterface(address _cinemaContractAddress) external {
        cinemaInterface = ICinema(_cinemaContractAddress);
    }

    function updateUserTransactions(
        uint256 _region,
        uint256 _cinema,
        bytes32 _ticket
    ) external {
        UserDetails storage details = userToDetails[msg.sender];
        uint256 transactionAmount = details.transactionAmount[_region][_cinema];
        uint256 newTransactionAmount = transactionAmount + 1;
        details.transactionDetails[_region][_cinema][
            newTransactionAmount
        ] = _ticket;
        details.transactionAmount[_region][_cinema] = newTransactionAmount;
    }

    function addSuperAdmins(address[] memory _newAdmins) public onlyOwner {
        for (uint256 i; i < _newAdmins.length; ++i) {
            address newAdmin = _newAdmins[i];
            bool isAlreadyExisted = superAdminStatus[newAdmin];
            require(!isAlreadyExisted, "Address already existed");
            superAdminStatus[newAdmin] = true;
        }
    }

    function addCinemaAdmins(
        uint256 _region,
        uint256 _cinema,
        address[] calldata _newAdmins
    )
        external
        onlySuperAdmin
        isAdminExists(_newAdmins, _region, _cinema)
        isCinemaExist(_cinema, _region)
    {
        CinemaAdminsDetails storage details = cinemaAdminsDetails[_region][
            _cinema
        ];
        uint256 cinemaAdminsAmount = details.cinemaAdminsAmount;
        for (uint256 i; i < _newAdmins.length; ++i) {
            cinemaAdminsAmount++;
            AdminDetails storage adminDetails = details.adminDetails[
                _newAdmins[i]
            ];
            details.cinemaAdmins[cinemaAdminsAmount] = _newAdmins[i];
            details.cinemaAdminStatus[_newAdmins[i]] = true;
            adminDetails.cinema = uint32(_cinema);
            adminDetails.region = uint8(_region);
        }
        details.cinemaAdminsAmount = uint32(
            cinemaAdminsAmount + _newAdmins.length
        );
    }

    function checkAdmin(
        uint256 _region,
        uint256 _cinema,
        address _admin
    ) external view returns (bool result) {
        CinemaAdminsDetails storage details = cinemaAdminsDetails[_region][
            _cinema
        ];
        result = details.cinemaAdminStatus[_admin];
    }
}
