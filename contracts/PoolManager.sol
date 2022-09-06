// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./Authorizable.sol";
import "./interfaces/IRewardPool.sol";

contract PoolManager is Authorizable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    EnumerableSet.AddressSet private newPoolList;
    EnumerableSet.AddressSet private legacyPoolList;

    event AddPool(address pool, bool isLegacy);
    event RemovePools(address[] pools, bool isLegacy);
    event GovernanceTokenChange(IERC20 newGovernanceToken);

    constructor() {}

    /*
        Write Functions - Permissioned
    */

    function addPool(address _pool, bool _isLegacy) public onlyAuthorized {
        IRewardPool pool = IRewardPool(_pool);
        if (_isLegacy) {
            if (
                !legacyPoolList.contains(_pool) &&
                pool.stakeToken() != address(0)
            ) {
                legacyPoolList.add(_pool);
            }
        } else {
            if (
                !newPoolList.contains(_pool) && pool.STAKE_TOKEN() != address(0)
            ) {
                newPoolList.add(_pool);
            }
        }

        emit AddPool(_pool, _isLegacy);
    }

    function addPools(address[] calldata _pools, bool _isLegacy)
        public
        onlyAuthorized
    {
        for (uint256 i = 0; i < _pools.length; i++) {
            addPool(_pools[i], _isLegacy);
        }
    }

    function removePools(address[] calldata _pools, bool _isLegacy)
        public
        onlyAuthorized
    {
        if (_isLegacy) {
            for (uint256 i = 0; i < _pools.length; i++) {
                legacyPoolList.remove(_pools[i]);
            }
        } else {
            for (uint256 i = 0; i < _pools.length; i++) {
                newPoolList.remove(_pools[i]);
            }
        }

        emit RemovePools(_pools, _isLegacy);
    }

    /*
        Read Functions - Public 
    */

    function allNewPools() external view returns (address[] memory) {
        return newPoolList.values();
    }

    function allLegacyPools() external view returns (address[] memory) {
        return legacyPoolList.values();
    }

    function getActivePoolCount() external view returns (uint256) {
        uint256 count = 0;

        for (uint256 i = 0; i < newPoolList.length(); i++) {
            address pool = newPoolList.at(i);
            uint256 endBlock = IRewardPool(pool).bonusEndBlock();
            if (endBlock > block.number) {
                ++count;
            }
        }

        for (uint256 i = 0; i < legacyPoolList.length(); i++) {
            address pool = legacyPoolList.at(i);
            uint256 endBlock = IRewardPool(pool).bonusEndBlock();
            if (endBlock > block.number) {
                ++count;
            }
        }

        return count;
    }

    function allActivePools() external view returns (address[] memory) {
        address[] memory _activePoolList = new address[](
            this.getActivePoolCount()
        );
        uint256 count = 0;

        for (uint256 i = 0; i < newPoolList.length(); i++) {
            address pool = newPoolList.at(i);
            uint256 endBlock = IRewardPool(pool).bonusEndBlock();
            if (endBlock > block.number) {
                _activePoolList[count] = pool;
                ++count;
            }
        }

        for (uint256 i = 0; i < legacyPoolList.length(); i++) {
            address pool = legacyPoolList.at(i);
            uint256 endBlock = IRewardPool(pool).bonusEndBlock();
            if (endBlock > block.number) {
                _activePoolList[count] = pool;
                ++count;
            }
        }

        return _activePoolList;
    }
}
