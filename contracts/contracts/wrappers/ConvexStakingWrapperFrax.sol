// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ConvexStakingWrapper.sol";

interface IFraxFarm {
    function lockedLiquidityOf(address account) external view returns (uint256 amount);
}

//Staking wrapper for Frax Finance platform
//use convex LP positions as collateral while still receiving rewards
contract ConvexStakingWrapperFrax is ConvexStakingWrapper {
    using SafeERC20
    for IERC20;
    using SafeMath
    for uint256;

    constructor() public{}

    function initialize(uint256 _poolId)
    override external {
        require(!isInit,"already init");
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);

        (address _lptoken, address _token, , address _rewards, , ) = IBooster(convexBooster).poolInfo(_poolId);
        curveToken = _lptoken;
        convexToken = _token;
        convexPool = _rewards;
        convexPoolId = _poolId;

        _tokenname = string(abi.encodePacked("Staked ", ERC20(_token).name(), " Frax" ));
        _tokensymbol = string(abi.encodePacked("stk", ERC20(_token).symbol(), "-frax"));
        isShutdown = false;
        isInit = true;

        //set vault later
        // collateralVault = _vault;


        //add rewards
        addRewards();
        setApprovals();
    }

    function setVault(address _vault) external onlyOwner{
        require(collateralVault == address(0), "already set");

        collateralVault = _vault;
    }

    function _getDepositedBalance(address _account) internal override view returns(uint256) {
        if (_account == address(0) || _account == collateralVault) {
            return 0;
        }

        uint256 collateral;
        if(collateralVault != address(0)){
           collateral = IFraxFarm(collateralVault).lockedLiquidityOf(_account);
        }

        return balanceOf(_account).add(collateral);
    }
}