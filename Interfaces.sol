// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";

interface IMainContract {
    
    function getNickName(uint256 tokenId) external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function getRewardContract() external view returns (address);
}

interface ITraitChangeCost {
    struct TraitChangeCost {
        uint8 minValue;
        uint8 maxValue;
        bool allowed;
        uint32 changeCostEthMillis;
        uint32 increaseStepCostEthMillis;
        uint32 decreaseStepCostEthMillis;
    }
}
