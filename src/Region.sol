// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./IRoles.sol";

contract Region {
    struct RegionDetails {
        bytes32 name;
        uint8 cinemasAmount;
        mapping(uint256 => uint32) cinemas;
    }

    IRoles internal rolesInterface;
    uint256 private regionsAmount;

    mapping(uint256 => uint256) public activeRegions;
    mapping(uint256 => bool) public activeRegionsStatus;
    mapping(uint256 => RegionDetails) public regionToDetails;

    modifier onlySuperAdmin() {
        bool result = rolesInterface.isSuperAdmin();
        require(result, "You're not a super admin");
        _;
    }

    modifier isRegionActive(uint256 _region) {
        bool result = activeRegionsStatus[_region];
        require(!result, "Region already active");
        _;
    }

    function getRegions() external view returns (uint256[] memory regions) {
        uint256 amount = regionsAmount;
        regions = new uint256[](amount);
        for (uint256 i; i < amount; ++i) {
            regions[i] = activeRegions[i];
        }
    }

    function getRegionsDetails(uint256 _region)
        public
        view
        returns (
            bytes32 _name,
            uint256 _cinemasAmount,
            uint256[] memory _cinemas
        )
    {
        RegionDetails storage regionDetails = regionToDetails[_region];
        return (
            regionDetails.name,
            regionDetails.cinemasAmount,
            getCinemasInRegion(_region)
        );
    }

    function getCinemasInRegion(uint256 _region)
        public
        view
        returns (uint256[] memory cinemas)
    {
        RegionDetails storage regionDetails = regionToDetails[_region];
        uint256 cinemasAmount = regionDetails.cinemasAmount;
        cinemas = new uint256[](cinemasAmount);
        for (uint256 i; i < cinemasAmount; ++i) {
            uint256 cinema = regionDetails.cinemas[i];
            cinemas[i] = cinema;
        }
    }

    function checkCinemaInRegion(uint256 _region, uint256 _cinema)
        public
        view
        returns (bool result)
    {
        RegionDetails storage regionDetails = regionToDetails[_region];
        uint256 cinemasAmount = regionDetails.cinemasAmount;
        for (uint256 i; i < cinemasAmount; ++i) {
            uint256 cinema = regionDetails.cinemas[i + 1];
            if (cinema == _cinema) {
                result = true;
            }
        }
    }

    function addRegion(uint256 _region, bytes32 _name)
        external
        onlySuperAdmin
        isRegionActive(_region)
    {
        uint256 currentRegionAmount = regionsAmount;
        activeRegionsStatus[_region] = true;
        RegionDetails storage details = regionToDetails[_region];
        details.cinemasAmount = 0;
        details.name = _name;
        regionsAmount = uint8(currentRegionAmount + 1);
    }

    function addCinemasInRegion(uint256 _region, uint256[] calldata _cinemas)
        public
    {
        RegionDetails storage regionDetails = regionToDetails[_region];
        uint256 currentCinemasAmount = regionDetails.cinemasAmount;
        for (uint256 i; i < _cinemas.length; ++i) {
            regionDetails.cinemas[currentCinemasAmount] = uint32(_cinemas[i]);
            currentCinemasAmount += 1;
        }
        regionDetails.cinemasAmount = uint8(currentCinemasAmount);
    }

    function deleteRegion(uint256 _region) external onlySuperAdmin {}
}
