// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
//Ownable is needed to setup sales royalties on Open Sea
//if you are the owner of the contract you can configure sales Royalties in the Open Sea website
import "@openzeppelin/contracts/access/Ownable.sol";
//the rarible dependency files are needed to setup sales royalties on Rarible 
//import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
//import "./@rarible/royalties/contracts/LibPart.sol";
//import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./Interfaces.sol";
import "./YieldTokenContract.sol";
import "./TokenUriLogicContract.sol";


contract MutantBitBirds is ERC721, ERC721Enumerable, Pausable, Ownable, ERC2981, ITraitChangeCost { //, RoyaltiesV2Impl {
    using Strings for uint256;
    using Counters for Counters.Counter;

    YieldTokenContract public YieldToken; 
    TokenUriLogicContract public TokenUriLogic;
    address public BreedTokensContract = address(0);   
    bool BreedTokensContractIsErc1155;
    bool YieldTokenWithdrawalAllowed = false;
    bool FreeMintAllowed = false;
    bool PublicMintAllowed = false; 
    bool BreedMintAllowed = false;        
	     
    mapping(address => uint16) public BreedAddressCount;
    mapping(uint256 => uint256) public BreedTokenIds;   
    mapping(uint256 => string) public TokenIdNickName;     
	uint16 public MaxTotalSupply; 
	uint16 public MaxBreedSupply;
    uint16 public CurrentBreedSupply = 0;    
	uint16 public CurrentReserveSupply;    
	uint16 public CurrentPublicSupply;              
	uint16 public MintMaxTotalBalance = 5;
	uint32 public NickNameChangePriceEthMillis = 100* 1000; // 100 eth-yield tokens (1000 == 1 eth-yield)    
	uint256 public MintTokenPriceEth = 50000000000000000; // 0.050 ETH
    uint256 public MintTokenPriceUsdc = 50000000000000000000; // 50 USDT
    
	bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;  
    Counters.Counter private _tokenIdCounter;
    address constant public RewardContract = address(0xE8aF6d7e77f5D9953d99822812DCe227551df1D7);     
    ERC20 private _tokenWEth = ERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6); // goerli addr    
    ERC20 private _tokenUsdc = ERC20(0x2f3A40A3db8a7e3D09B0adfEfbCe4f6F81927557); // goerli addr    
    //bool _mintAllowWEthPayment = true;
    //bool _mintAllowUsdtPayment = true;

    constructor(uint16 maxTotalSupply, uint16 reserveSupply, uint16 maxBreedSupply) ERC721("MutantBitBirds", "MTB") {
        require(maxTotalSupply > 0, "err supply");
	    require(reserveSupply + maxBreedSupply <= maxTotalSupply, "err reserve");
        MaxTotalSupply = maxTotalSupply;
        MaxBreedSupply = maxBreedSupply;
        CurrentReserveSupply = reserveSupply;
        CurrentPublicSupply = MaxTotalSupply - reserveSupply - maxBreedSupply;        
		_setDefaultRoyalty(msg.sender, 850);
	    //reserveMint(msg.sender, 1);
        _pause();
	}

	function getRewardContract() public pure returns(address) {
        return RewardContract;
    }

    function setTokenUriLogic(address tokenUriLogic) external onlyOwner {
		TokenUriLogic = TokenUriLogicContract(tokenUriLogic);
	}    

	function setYieldToken(address yieldtkn) external onlyOwner {
		YieldToken = YieldTokenContract(yieldtkn);
	}    

    function setYieldTokenWithdrawalAllowed(bool allowed) external onlyOwner {
        YieldTokenWithdrawalAllowed = allowed;
    }

    function withdrawYieldTokenReward() external whenNotPaused() {
        require(YieldTokenWithdrawalAllowed, "not allowed yet");
		YieldToken.updateReward(msg.sender, address(0)/*, 0*/);
		YieldToken.getReward(msg.sender);
	}

    function getYieldTokenClaimable(address user) external view returns(uint256) {
        return YieldToken.getTotalClaimable(user);
    }

    function setBreedTokensContract(address breedTokenContract, bool isErc1155) external onlyOwner {
        BreedTokensContract = breedTokenContract;   
        BreedTokensContractIsErc1155 = isErc1155;        
	}  

	function setMintOptionsAllowed(bool freeMintAllowed, bool breedMintAllowed, bool publicMintAllowed) external onlyOwner {
        if (freeMintAllowed != FreeMintAllowed)
            FreeMintAllowed = freeMintAllowed;
        if (breedMintAllowed != BreedMintAllowed)
            BreedMintAllowed = breedMintAllowed;
        if (publicMintAllowed != PublicMintAllowed)
            PublicMintAllowed = publicMintAllowed;            
    }  

    // Opensea json metadata format interface
    function contractURI() external view returns (string memory) {
        return TokenUriLogic.contractURI();        
     }

    function internalMint(address to) internal whenNotPaused returns(uint256) {
        uint256 tokenId = _tokenIdCounter.current();        
        require(tokenId < MaxTotalSupply, "max supply");	
        _tokenIdCounter.increment();
        tokenId = tokenId + 1;
        _safeMint(to, tokenId);
        TokenUriLogic.randInitTokenDNA(tokenId);
        //setRoyalties(tokenId, owner(), 1000);
        return tokenId;
    }	

    function reserveMint(address to, uint16 quantity) external onlyOwner {
        require(quantity > 0, "cannot be zero");
        require(CurrentReserveSupply >= quantity, "no reserve");
        CurrentReserveSupply = CurrentReserveSupply - quantity;
        for (uint i = 0; i < quantity; i++) 
		    internalMint(to);
    }

    function walletHoldsBreedToken(uint256 breedTokenId, address wallet) public view returns (bool) {
        if (BreedTokensContractIsErc1155)
            return IERC1155(BreedTokensContract).balanceOf(wallet, breedTokenId) > 0;
        else
            return IERC721(BreedTokensContract).ownerOf(breedTokenId) == wallet;
    }

	/*
    function isValidBreedToken(uint256 id) view internal returns(bool) {
		// making sure the ID fits the opensea format:
		// first 20 bytes are the maker address
		// next 7 bytes are the nft ID
		// last 5 bytes the value associated to the ID, here will always be equal to 1
		//if (id >> 96 != 0x000000000000000000000000a2548e7ad6cee01eeb19d49bedb359aea3d8ad1d)
        if (id >> 96 != uint256(uint160(_breedTokensContract)))
			return false;
		if (id & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1)
			return false;
		//uint256 id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
		//if (id > 1005 || id == 262 || id == 197 || id == 75 || id == 34 || id == 18 || id == 0)
		//	return false;
		return true;
	}
    */     

    function breedMint(uint16 quantity, uint256[] calldata breedtokens) public {
        require(BreedMintAllowed, "not allowed");
        require(BreedTokensContract != address(0), "no breed");
        require(quantity > 0, "cannot be zero");        
		require(msg.sender == tx.origin, "no bots");        
        require(quantity == breedtokens.length, "tokens err");
        require(CurrentBreedSupply + quantity <= MaxBreedSupply, "no reserve");
        for (uint i = 0; i < quantity; i++) 
        {
            require(BreedTokenIds[breedtokens[i]]== 0, "bread yet");
            //require(isValidBreedToken(breedtokens[i]), "token err");            
            require(walletHoldsBreedToken(breedtokens[i], msg.sender) || (msg.sender == owner()), "no owner");
		    BreedTokenIds[breedtokens[i]] = internalMint(msg.sender);
        }
        CurrentBreedSupply = CurrentBreedSupply + quantity;
        BreedAddressCount[msg.sender] = BreedAddressCount[msg.sender] + quantity;
        YieldToken.updateRewardOnMint(msg.sender, quantity);           
    }
	
	function publicMint(address user, uint16 quantity) internal  {
        require(PublicMintAllowed, "not allowed");
        require(quantity > 0, "cannot be zero");
		//require(msg.sender == tx.origin, "no bots");		
        require(CurrentPublicSupply >= quantity);	
		require(balanceOf(user) - BreedAddressCount[user] + quantity <= MintMaxTotalBalance, "too many");
        for (uint i = 0; i < quantity; i++) 
        {
		    internalMint(user);
        }
        CurrentPublicSupply = CurrentPublicSupply - quantity;	
        YieldToken.updateRewardOnMint(user, quantity);
	}

    function publicMintFree() external {
		require(FreeMintAllowed, "not allowed");	 
        publicMint(msg.sender, 1);       
    }

    function publicMintEth(uint16 quantity) external payable {
		require(msg.value == quantity * MintTokenPriceEth, "wrong price");
        require(msg.sender == tx.origin, "no bots");	 
        publicMint(msg.sender, quantity);       
    }

    function AcceptWEthPayment(address user, uint32 quantity) internal  {
        bool success = _tokenWEth.transferFrom(user, address(this), quantity * MintTokenPriceEth);
        require(success, "Could not transfer token. Missing approval?");
    }

    function publicMintWEth(uint16 quantity) external /*payable*/ {
        require(address(_tokenWEth) != address(0), "not enabled");
        require(msg.sender == tx.origin, "no bots");
        AcceptWEthPayment(msg.sender, quantity);
        publicMint(msg.sender, quantity);       
    }    

    function AcceptUsdcPayment(address user, uint32 quantity)  internal {
        bool success = _tokenUsdc.transferFrom(user, address(this), quantity * MintTokenPriceUsdc);
        require(success, "Could not transfer token. Missing approval?");
    }

    function publicMintUsdc(uint16 quantity) external /*payable*/ {
        require(address(_tokenUsdc) != address(0), "not enabled");
        require(msg.sender == tx.origin, "no bots");
        AcceptUsdcPayment(msg.sender, quantity);
        publicMint(msg.sender, quantity);       
    }       
				
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }	

    function ownedCount(address account) external view returns(uint256) {
        return balanceOf(account);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
		_resetTokenRoyalty(tokenId);
    }
	
	function burnNFT(uint256 tokenId) external onlyOwner() {
		_burn(tokenId);
	}		

	function setMintTokenPriceEth(uint256 mintTokenPriceEth) external onlyOwner() {
		MintTokenPriceEth = mintTokenPriceEth;
	}

    function setMintTokenWEth(address contractAddress) external onlyOwner() {
		_tokenWEth = ERC20(contractAddress);
	}

	function setMintTokenPriceUsdc(uint256 mintTokenPriceUsdc) external onlyOwner() {
		MintTokenPriceUsdc = mintTokenPriceUsdc;
	}

    function setMintTokenUsdc(address contractAddress) external onlyOwner() {
		_tokenUsdc = ERC20(contractAddress);
	}

 	function setMintMaxTotalBalance(uint16 mintMaxTotalBalance) external onlyOwner() {
		MintMaxTotalBalance = mintMaxTotalBalance;
	}

    function withdraw(uint256 amount, uint32 tokenchoice) external /*payable*/ onlyOwner {
        uint256 balance = address(this).balance;
        require(amount < balance);
        bool success;
        if (tokenchoice == 0) {
            success = _tokenWEth.transfer(RewardContract, amount);
        }
        else if (tokenchoice == 1) {
            success = _tokenUsdc.transfer(RewardContract, amount);
        }
        else {
            (success, ) = payable(/*msg.sender*/RewardContract).call{value: amount}("");
        }
		require(success, "Failed to send Ether");
    }	  

    function getNickName(uint256 tokenId) external view returns (string memory ) {
         require(_exists(tokenId), "token err");
         return string(TokenIdNickName[tokenId]);
    }

    function validateNickName(string calldata str) public pure returns (bool){
		bytes memory b = bytes(str);
		if(b.length < 1) return false;
		if(b.length > 16) return false;
		if(b[0] == 0x20) return false; // Leading space
		if (b[b.length - 1] == 0x20) return false; // Trailing space

		bytes1 lastChar = b[0];

		for(uint i; i<b.length; i++){
			bytes1 char = b[i];

			if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

			if(
				!(char >= 0x30 && char <= 0x39) && //9-0
				!(char >= 0x41 && char <= 0x5A) && //A-Z
				!(char >= 0x61 && char <= 0x7A) && //a-z
				!(char == 0x20) //space
			)
				return false;

			lastChar = char;
		}

		return true;
	} 

	function setNickNamePrice(uint32 changeNickNamePriceEthMillis) external onlyOwner {
		NickNameChangePriceEthMillis = changeNickNamePriceEthMillis;
	}

    function spendYieldTokens(address user, uint256 amount) internal {
        //require(YieldToken != address(0), "yield not set");
        if (YieldTokenWithdrawalAllowed) {
            require(YieldToken.balanceOf(user) >= amount, "cawSeed balance");
            YieldToken.burn(user, amount);
        }
        else {
            require(/*YieldToken.balanceOf(user) +*/ YieldToken.getTotalClaimable(user) >= amount, "cawSeed available");
            YieldToken.updateReward(user, address(0)/*, 0*/);
            YieldToken.collect(user, amount);
        }        
    }

	function setNickName(uint256 tokenId, string calldata nickname) external {
        require(_exists(tokenId), "token err");
        require(ownerOf(tokenId) == msg.sender, "no owner");
        require(validateNickName(nickname), "refused");
        uint256 cost = NickNameChangePriceEthMillis;
        spendYieldTokens(msg.sender, (cost * 1000000000000000));
        TokenIdNickName[tokenId] = nickname;
    }    

	function setTraitValue(uint256 tokenId, uint8 traitId, uint8 traitValue) external {
        require(_exists(tokenId), "token err");
        require(ownerOf(tokenId) == msg.sender, "no owner");        
        TraitChangeCost memory tc = TokenUriLogic.getTraitCost(traitId);
        require(tc.allowed, "not allowed");
        require(tc.minValue <= traitValue, "minValue");
        require(tc.maxValue >= traitValue, "maxValue");
        uint8 currentValue = TokenUriLogic.getTraitValue(tokenId, traitId);
        require(currentValue != traitValue, "currentValue");
        uint256 cost = tc.changeCostEthMillis;
        if (traitValue > currentValue) {
              cost = cost + tc.increaseStepCostEthMillis * (traitValue - currentValue);
        }
        else {
              cost = cost + tc.decreaseStepCostEthMillis * (currentValue - traitValue);
        }
        spendYieldTokens(msg.sender, (cost * 1000000000000000)); 
        TokenUriLogic.setTraitValue(tokenId, traitId, traitValue);
	}	    	
		
    function tokenURI(uint256 tokenId)
        public
        view
        virtual override(ERC721)
        returns (string memory)
    {
        return TokenUriLogic.tokenURI(ownerOf(tokenId), tokenId);
    }	
	
	function walletOf(address wladdress)
		public
		view
		returns (uint256[] memory)
	  {
		uint256 ownerTokenCount = balanceOf(wladdress);
		uint256[] memory tokenIds = new uint256[](ownerTokenCount);
		for (uint256 i; i < ownerTokenCount; i++) {
		  tokenIds[i] = tokenOfOwnerByIndex(wladdress, i);
		}
		return tokenIds;
	  }
	  
	  /*
      function reveal() public onlyOwner {
		  _revealed = true;
	  }	
    */
	
    /*
    //configure royalties for Rarible
    function setRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }


    //configure royalties for Mintable using the ERC2981 standard
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      //use the same royalties that were saved for Rariable
      LibPart.Part[] memory _royalties = royalties[_tokenId];
      if(_royalties.length > 0) {
        return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
      }
      return (address(0), 0);
    }
    */    

	function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
		YieldToken.updateReward(from, to/*, tokenId*/);
		super.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override(ERC721, IERC721) {
		YieldToken.updateReward(from, to/*, tokenId*/);
		super.safeTransferFrom(from, to, tokenId, _data);
	}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        /*
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        */

        if (interfaceId == _INTERFACE_ID_ERC2981) {
          return true;
        }	

        return super.supportsInterface(interfaceId);
    }
}
