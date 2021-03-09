// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract bsFactory is ERC20("bsFactory", "bsUSDC"), Ownable {
    using SafeMath for uint256;
    IERC20 public token;

    struct UserInfo {
        uint amount;
        uint lastStakeTime;
        uint lockedTime;
    }

    uint maxLockedDays = 150;

    mapping(address => UserInfo) public userInfo;

    constructor(IERC20 _token) public {
        token = _token;
    }

    function enter(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        user.amount = user.amount.add(_amount);
        user.lastStakeTime = block.timestamp;
        user.lockedTime = block.timestamp + 60 * 60 * 24 * maxLockedDays;
        _mint(msg.sender, _amount);
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function leave(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        user.amount = user.amount.sub(_amount);
        _burn(msg.sender, _amount);
        token.transfer(msg.sender, _amount);
    }

    function calculateRewards(address _address, uint256 _apy) public view returns (uint256) {
        UserInfo storage user = userInfo[_address];
        uint256 rewards = 0;

        if (user.amount > 0 && user.lastStakeTime > 0) {
            rewards = (((user.amount.mul(_apy.div(100))).div(365*24*60*60)).mul(block.timestamp - user.lastStakeTime)).div(1e18);
        }

        return rewards;
    }

    function setMaxLockedDays(uint _maxLockedDays) public onlyOwner {
        maxLockedDays = _maxLockedDays;
    }
}