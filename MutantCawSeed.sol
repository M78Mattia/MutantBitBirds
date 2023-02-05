// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMBBcontract {
	function balanceOf(address _user) external view returns(uint256);
}

contract MutantCawSeed is ERC20, Ownable {

	uint256 constant public BASE_RATE_XSEC = 34722222222223; // * 3 eth (daily) / 86400 (seconds in a day)
	uint256 constant public MINT_GIFT = 100 ether;
	//  Apr 30 2033 13:33:33 GMT+0000
	uint256 constant public END = 1998480813;

	mapping(address => uint256) public rewards;
	mapping(address => uint256) public lastUpdate;

	IMBBcontract public  _MBBContract;

	event RewardPaid(address indexed user, uint256 reward);

    constructor(address mbbcntr) ERC20("MutantCawSeed", "MCS") {
		_MBBContract = IMBBcontract(mbbcntr);
	}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

    // called when minting many NFTs
	// updated_amount = (balanceOG(user) * base_rate * delta / 86400) + amount * initial rate
	function updateRewardOnMint(address _user, uint16 _amount) external {
		require(msg.sender == address(_MBBContract), "Can't call this");
		uint256 time = min(block.timestamp, END);
		uint256 timerUser = lastUpdate[_user];
        if (timerUser > 0) {
            uint256 reward = rewards[_user] + (_MBBContract.balanceOf(_user) * BASE_RATE_XSEC * (time - timerUser));
            reward = reward + _amount * MINT_GIFT;
			rewards[_user] = reward;
        }
		else {
			rewards[_user] = rewards[_user] + _amount * MINT_GIFT;
        }
		lastUpdate[_user] = time;
	}

	// called on transfers
	function updateReward(address _from, address _to/*, uint256 _tokenId*/) external {
		require(msg.sender == address(_MBBContract));
		//if (_tokenId < 1001) {
			uint256 time = min(block.timestamp, END);
			uint256 timerFrom = lastUpdate[_from];
			if (timerFrom > 0)
				rewards[_from] += (_MBBContract.balanceOf(_from) * BASE_RATE_XSEC * (time - timerFrom));
			if (timerFrom != END)
				lastUpdate[_from] = time;
			if (_to != address(0)) {
				uint256 timerTo = lastUpdate[_to];
				if (timerTo > 0)
					rewards[_to] += (_MBBContract.balanceOf(_to) * BASE_RATE_XSEC * (time - timerTo));
				if (timerTo != END)
					lastUpdate[_to] = time;
			}
		//}
	}

	function getReward(address _to) external {
		require(msg.sender == address(_MBBContract));
		uint256 reward = rewards[_to];
		if (reward > 0) {
			rewards[_to] = 0;
			_mint(_to, reward);
			emit RewardPaid(_to, reward);
		}
	}

	function burn(address _from, uint256 _amount) external {
		require(msg.sender == address(_MBBContract));
		_burn(_from, _amount);
	}
	
    /*function getTotalOwned(address _user) external view returns(uint256) {
        return _MBBContract.balanceOf(_user);
    }*/    

	function getTotalClaimable(address _user) external view returns(uint256) {
		uint256 time = min(block.timestamp, END);
        uint256 pending = 0;
        if (lastUpdate[_user] > 0 && time > lastUpdate[_user])
            pending = (_MBBContract.balanceOf(_user) * BASE_RATE_XSEC * (time- lastUpdate[_user]));
		return rewards[_user] + pending;
	}
}
