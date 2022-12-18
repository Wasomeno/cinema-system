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

    mapping(uint256 => bool) public activeRegions;
    mapping(uint256 => RegionDetails) public regionToDetails;

    modifier onlySuperAdmin() {
        bool result = rolesInterface.isSuperAdmin();
        require(result, "You're not a super admin");
        _;
    }

    modifier isRegionActive(uint256 _region) {
        bool result = activeRegions[_region];
        require(!result, "Region already active");
        _;
    }

    function getRegions() external view returns (uint256[] memory regions) {
        uint256 amount = regionsAmount;
        regions = new uint256[](amount);
        for (uint256 i; i < amount; ++i) {
            regions[i] = i + 1;
        }
    }

    function getRegionsDetails(uint256 _region)
        internal
        view
        returns (RegionDetails storage details)
    {
        details = regionToDetails[_region];
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
        activeRegions[currentRegionAmount + 1] = true;
        RegionDetails storage details = regionToDetails[_region];
        details.cinemasAmount = 0;
        details.name = _name;
        regionsAmount = uint8(currentRegionAmount + 1);
    }
}
