// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../src/Region.sol";
import "../src/Roles.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";

contract RegionTest is Test {
    Region regionContract;
    Roles rolesContract;

    uint256 REGIONS_GENERATE_AMOUNT = 5;
    string DEFAULT_REGION_NAME = "Region";
    uint256 DEFAULT_REGION_ID = 1;

    function setUp() public {
        regionContract = new Region();
        rolesContract = new Roles();
        regionContract.setInterface(address(rolesContract));
    }

    function generateRegions()
        internal
        view
        returns (uint256[] memory regions, bytes32[] memory names)
    {
        uint256 amount = REGIONS_GENERATE_AMOUNT;
        regions = new uint256[](amount);
        names = new bytes32[](amount);
        uint256 regionId = DEFAULT_REGION_ID;
        string memory regionName = DEFAULT_REGION_NAME;
        for (uint256 i; i < amount; ++i) {
            regions[i] = regionId;
            names[i] = keccak256(abi.encode(regionName, regionId));
            regionId += 1;
        }
    }

    function testAddNewRegions() public {
        (uint256[] memory regions, bytes32[] memory names) = generateRegions();
        for (uint256 i; i < 5; ++i) {
            regionContract.addRegion(regions[i], names[i]);
        }
    }

    function testDeleteRegions() public {
        (uint256[] memory regions, bytes32[] memory names) = generateRegions();
        for (uint256 i; i < 5; ++i) {
            regionContract.addRegion(regions[i], names[i]);
        }

        for (uint256 i; i < 5; ++i) {
            regionContract.deleteRegion(regions[i]);
        }
        bool regionStatus = regionContract.activeRegionsStatus(4);
        uint256 region = regionContract.activeRegions(4);
        console.log(region);
    }

    function testUpdateName() public {
        (uint256[] memory regions, bytes32[] memory names) = generateRegions();
        for (uint256 i; i < 5; ++i) {
            regionContract.addRegion(regions[i], names[i]);
        }
        bytes32 newName = keccak256(abi.encode("Change Region Name"));
        regionContract.updateRegionName(2, newName);
    }
}
