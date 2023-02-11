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

	mapping(address => uint256) public Rewards;
	mapping(address => uint256) public LastUpdate;

	IMBBcontract public  MBBContract;

	event RewardPaid(address indexed user, uint256 reward);

    constructor(address mbbcntr) ERC20("MutantCawSeed", "MCS") {
		MBBContract = IMBBcontract(mbbcntr);
	}

    function mint(address to, uint256 amount) public {
    	require (msg.sender == address(MBBContract) || msg.sender == owner());
        _mint(to, amount);
    }

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

    // called when minting many NFTs
	// updated_amount = (balanceOG(user) * base_rate * delta / 86400) + amount * initial rate
	function updateRewardOnMint(address _user, uint16 _amount) external {
		require(msg.sender == address(MBBContract), "Can't call this");
		uint256 time = min(block.timestamp, END);
		uint256 timerUser = LastUpdate[_user];
        if (timerUser > 0) {
            uint256 reward = Rewards[_user] + (MBBContract.balanceOf(_user) * BASE_RATE_XSEC * (time - timerUser));
            reward = reward + _amount * MINT_GIFT;
			Rewards[_user] = reward;
        }
		else {
			Rewards[_user] = Rewards[_user] + _amount * MINT_GIFT;
        }
		LastUpdate[_user] = time;
	}

	// called on transfers
	function updateReward(address _from, address _to/*, uint256 _tokenId*/) external {
		require(msg.sender == address(MBBContract));
		//if (_tokenId < 1001) {
			uint256 time = min(block.timestamp, END);
			uint256 timerFrom = LastUpdate[_from];
			if (timerFrom > 0)
				Rewards[_from] += (MBBContract.balanceOf(_from) * BASE_RATE_XSEC * (time - timerFrom));
			if (LastUpdate[_from] != END)
				LastUpdate[_from] = time;
			if (_to != address(0)) {
				uint256 timerTo = LastUpdate[_to];
				if (timerTo > 0)
					Rewards[_to] += (MBBContract.balanceOf(_to) * BASE_RATE_XSEC * (time - timerTo));
				if (LastUpdate[_to] != END)
					LastUpdate[_to] = time;
			}
		//}
	}

	function getReward(address _to) external {
		require(msg.sender == address(MBBContract));
		uint256 reward = Rewards[_to];
		if (reward > 0) {
			Rewards[_to] = 0;
			_mint(_to, reward);
			emit RewardPaid(_to, reward);
		}
	}

	function burn(address _from, uint256 _amount) external {
		require(msg.sender == address(MBBContract));
		_burn(_from, _amount);
	}
	
    /*function getTotalOwned(address _user) external view returns(uint256) {
        return _MBBContract.balanceOf(_user);
    }*/    

	function getTotalClaimable(address _user) external view returns(uint256) {
		uint256 time = min(block.timestamp, END);
        uint256 pending = 0;
        if (LastUpdate[_user] > 0 && time > LastUpdate[_user])
            pending = (MBBContract.balanceOf(_user) * BASE_RATE_XSEC * (time - LastUpdate[_user]));
		return Rewards[_user] + pending;
	}
}
