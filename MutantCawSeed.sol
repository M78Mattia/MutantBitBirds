// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
	function updateRewardOnMint(address user, uint16 amount) external {
		require(msg.sender == address(MBBContract), "Can't call this");
		uint256 time = min(block.timestamp, END);
		uint256 timerUser = LastUpdate[user];
        if (timerUser > 0) {
            uint256 reward = Rewards[user] + (MBBContract.balanceOf(user) * BASE_RATE_XSEC * (time - timerUser));
            reward = reward + amount * MINT_GIFT;
			Rewards[user] = reward;
        }
		else {
			Rewards[user] = Rewards[user] + amount * MINT_GIFT;
        }
		LastUpdate[user] = time;
	}

	// called on transfers
	function updateReward(address from, address to/*, uint256 _tokenId*/) external {
		require(msg.sender == address(MBBContract));
		//if (_tokenId < 1001) {
			uint256 time = min(block.timestamp, END);
			uint256 timerFrom = LastUpdate[from];
			if (timerFrom > 0 && time > timerFrom)
				Rewards[from] = Rewards[from] + (MBBContract.balanceOf(from) * BASE_RATE_XSEC * (time - timerFrom));
			if (timerFrom != END && time > timerFrom)
				LastUpdate[from] = time;
			if (to != address(0)) {
				uint256 timerTo = LastUpdate[to];
				if (timerTo > 0 && time > timerTo)
					Rewards[to] = Rewards[to] + (MBBContract.balanceOf(to) * BASE_RATE_XSEC * (time - timerTo));
				if (timerTo != END && time > timerTo)
					LastUpdate[to] = time;
			}
		//}
	}

	function getReward(address to) external {
		require(msg.sender == address(MBBContract));
		uint256 reward = Rewards[to];
		if (reward > 0) {
			Rewards[to] = 0;
			_mint(to, reward);
			emit RewardPaid(to, reward);
		}
	}

	function burn(address from, uint256 amount) external {
		require(msg.sender == address(MBBContract));
		_burn(from, amount);
	}
	
	function collect(address from, uint256 amount) external {
		require(msg.sender == address(MBBContract));
		uint256 rew = Rewards[from];
		require(rew >= amount, "amount");
		Rewards[from] = rew - amount;
		//console.log("reward %s - collect %s tokens from %s - balance", from, amount, rew, Rewards[from]);
	} 

	function getTotalClaimable(address user) external view returns(uint256) {
		uint256 time = min(block.timestamp, END);
        uint256 pending = 0;
        if (LastUpdate[user] > 0 && time > LastUpdate[user])
            pending = (MBBContract.balanceOf(user) * BASE_RATE_XSEC * (time - LastUpdate[user]));
		return Rewards[user] + pending;
	}
}
