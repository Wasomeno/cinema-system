// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRegion {
    function getRegionsDetails(uint256 _region)
        external
        view
        returns (
            bytes32 _name,
            uint256 _cinemasAmount,
            uint256[] memory _cinemas
        );

    function checkCinemaInRegion(uint256 _region, uint256 _cinema)
        external
        view
        returns (bool result);

    function addCinemasInRegion(uint256 _region, uint256[] calldata _cinemas)
        external;
}
