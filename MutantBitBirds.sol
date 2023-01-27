// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

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


contract MutantBitBirds is ERC721, ERC721Enumerable, Pausable, Ownable, ERC2981 { //, RoyaltiesV2Impl {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint256) public _tokenIdDNA;	
	string private _contractUri = "https://rubykitties.tk/contract";
    string private _baseRevealedUri = "https://rubykitties.tk/kitties/";
	string private _baseNotRevealedUri = "https://rubykitties.tk/kitties/";
    string[] private _traitNames = ["tr-0", "tr-1", "tr-2", "tr-3", "tr-4", "tr-5", "tr-6", "tr-7"];
    uint256 private immutable TRAIT_MASK = 255;
	uint256 private _maxTotalSupply = 3000; 
	uint256 private _currentReserveSupply = 300;        
	uint256 private _mintMaxTotalBalance = 5;
	uint256 private _mintTokenPriceEth = 50000000000000000; // 0.050 ETH
	bool _revealed = false;
	bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor() ERC721("MutantBitBirds", "MTB") {
	
		_setDefaultRoyalty(msg.sender, 1000);
	    reserveMint(msg.sender, 1);
	}

    // Opensea json metadata format interface
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

	function setContractURI(string calldata contractUri) external onlyOwner() {
		_contractUri = contractUri;
	}    
	
    function internalMint(address to) internal {
		require(_tokenIdCounter.current() < _maxTotalSupply, "max supply");	
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
		_tokenIdDNA[tokenId] = 0;
		//setRoyalties(tokenId, owner(), 1000);
    }	

    function reserveMint(address to, uint quantity) public onlyOwner {
        require(quantity > 0, "cannot be zero");
        require(_currentReserveSupply > quantity, "no reserve");
        _currentReserveSupply = _currentReserveSupply -quantity;
        for (uint i = 0; i < quantity; i++) 
		    internalMint(to);
    }
	
	function publicMint(uint quantity) external payable {
        require(quantity > 0, "cannot be zero");
		require(msg.sender == tx.origin, "no bots");
		require(msg.value == quantity * _mintTokenPriceEth, "wrong price");		
		require(_tokenIdCounter.current() < _maxTotalSupply - quantity, "max supply");	
		require(balanceOf(msg.sender) + quantity < _mintMaxTotalBalance, "too many");
        for (uint i = 0; i < quantity; i++) 
		    internalMint(msg.sender);	
	}
				
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
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
	
	function setBaseRevealedUri(string calldata baseUri) external onlyOwner() {
		_baseRevealedUri = baseUri;
	}
	
	function setBaseNotRevealedUri(string calldata baseUri) external onlyOwner() {
		_baseNotRevealedUri = baseUri;
	}	

	function setTokenPriceEth(uint256 tokenPriceEth) external onlyOwner() {
		_mintTokenPriceEth = tokenPriceEth;
	}

	function getTokenPriceEth() public view returns (string memory) {
		return _mintTokenPriceEth.toString();
	}	

	function setMaxTotalSupply(uint256 maxTotalSupply) external onlyOwner() {
		_maxTotalSupply = maxTotalSupply;
	}

    function getCurrentReserveSupply() public view returns (string memory){
        return _currentReserveSupply.toString();
    }

    function getMaxTotalSupply() public view returns (string memory){
        return _maxTotalSupply.toString();
    }

	function setMintTokenPriceEth(uint256 mintTokenPriceEth) external onlyOwner() {
		_mintTokenPriceEth = mintTokenPriceEth;
	}

    function getMintTokenPriceEth() public view returns (string memory){
        return _mintTokenPriceEth.toString();
    }  
    
 	function setMintMaxTotalBalance(uint256 mintMaxTotalBalance) external onlyOwner() {
		_mintMaxTotalBalance = mintMaxTotalBalance;
	}

    function getMintMaxTotalBalance() public view returns (string memory){
        return _mintMaxTotalBalance.toString();
    }       
	    
    function withdraw(uint amount) public payable onlyOwner {
        uint balance = address(this).balance;
        require(amount < balance);
        (bool success, ) = payable(msg.sender).call{value: amount}("");
		require(success, "Failed to send Ether");
    }	  

	/*
    function incTraitValue(uint256 tokenId, uint8 traitId) public {
        require (traitId < 8, "trait err");        
		require(_exists(tokenId), "token err");
		require(ownerOf(tokenId) == msg.sender, "no owner");
		uint8 currentLevel = getTraitValue(tokenId, traitId);
		setTraitValue(tokenId, traitId, currentLevel + 1);
	}
    */

	function getTraitValues(uint256 tokenId) internal view returns (uint8[] memory ) {
        require(_exists(tokenId), "token err");
        uint256 oldvalue = _tokenIdDNA[tokenId];
        uint8[] memory traits = new uint8[](8);
        for (uint i = 0; i < 8; i++) 
        {
            uint256 bitMask = TRAIT_MASK << (8 * i);
            uint256 value = (oldvalue & bitMask) >> (8 * i); 
            traits[i] = uint8(value);           
        }     
        return traits;   
    }

	function getTraitValue(uint256 tokenId, uint8 traitId) public view returns (uint8 ) {
        require (traitId < 8, "trait err");
        require(_exists(tokenId), "token err");
		return getTraitValues(tokenId)[traitId];
	}

	function setTraitValue(uint256 tokenId, uint8 traitId, uint8 traitValue) public {
        require (traitId < 8, "trait err");
        require(_exists(tokenId), "token err");
        uint256 newvalue = traitValue;
        newvalue = newvalue << (8 *traitId);
        uint256 oldvalue = _tokenIdDNA[tokenId];
        for (uint i = 0; i < 8; i++) 
        {
            if (i != traitId)
            {
                uint256 bitMask = TRAIT_MASK << (8 * i);
                uint256 value = (oldvalue & bitMask); 
                newvalue |= value;
            }
        }
        _tokenIdDNA[tokenId] = newvalue;        
	}	    	
	
	function getImages(uint256 tokenId) public view returns (string memory) {
		if(_revealed == false) {
			return string(abi.encodePacked(_baseNotRevealedUri, tokenId.toString(), ".png"));
		}	
		return string(abi.encodePacked(_baseRevealedUri, tokenId.toString(), ".png"));
	}		
	
	function generateCharacter(uint256 tokenId) public view returns(bytes memory){
 		bytes memory svg = bytes.concat(
			'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" preserveAspectRatio="xMinYMin meet" viewBox="0 0 250 250">',
			'<style>.base { fill: white; font-family: serif; font-size: 14px; }</style>',
			'<rect width="100%" height="100%" fill="black" />',
			'<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">', 
            getTraitText(tokenId),        
            '</text>',
			'<image x="0" y="0" width="100" height="100" xlink:href="', 
            bytes(getImages(tokenId)), 
            '" />',
			'</svg>'
		);
		return bytes.concat(
				"data:image/svg+xml;base64,",
				bytes(Base64.encode(svg))
                );
	}
	
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        //return super.tokenURI(tokenId);
		return getTokenURI(tokenId);
    }	
	
    function getTraitAttributesTType(uint8 traitId, uint8 traitVal) internal view returns (bytes memory) {
        return bytes.concat("{\"trait_type\": \"", bytes(_traitNames[traitId]), "\",\"value\": \"", bytes(Strings.toString(traitVal)), "\"},");
    }

	function getTraitAttributes(uint256 tokenId) internal view returns (bytes memory) {
        uint8[] memory traits = getTraitValues(tokenId);     
        /*string memory attribs;
        for (uint8 i = 0; i < 8; i++) 
        {
            attribs = string.concat(attribs, getTraitAttributesTType(i, traits[i]));                        
        }
        return attribs;*/
        return 
			bytes.concat(
				getTraitAttributesTType(0, traits[0]),
				getTraitAttributesTType(1, traits[1]),
                getTraitAttributesTType(2, traits[2]),
                getTraitAttributesTType(3, traits[3]),
                getTraitAttributesTType(4, traits[4]),
                getTraitAttributesTType(5, traits[5]),
                getTraitAttributesTType(6, traits[6]),
                getTraitAttributesTType(7, traits[7])
			);	        
    }
	
    function getTraitTextTSpan(uint8 traitId, uint8 traitVal) internal view returns (bytes memory) {
        return bytes.concat("<tspan x=\"50%\" dy=\"15\">", bytes(_traitNames[traitId]), ": ", bytes(Strings.toString(traitVal)), "</tspan>");
    }

	function getTraitText(uint256 tokenId) internal view returns (bytes memory) {
        uint8[] memory traits = getTraitValues(tokenId);        
        /*string memory attribs;
        for (uint8 i = 0; i < 8; i++) 
        {
            attribs = string.concat(attribs, getTraitTextTSpan(i, traits[i]));
        }
        return attribs;*/
        return 
			bytes.concat(
				getTraitTextTSpan(0, traits[0]),
				getTraitTextTSpan(1, traits[1]),
                getTraitTextTSpan(2, traits[2]),
                getTraitTextTSpan(3, traits[3]),
                getTraitTextTSpan(4, traits[4]),
                getTraitTextTSpan(5, traits[5]),
                getTraitTextTSpan(6, traits[6]),
                getTraitTextTSpan(7, traits[7])
			);	                     
    }    

   function getTokenURImeta(uint256 tokenId) public view returns (bytes memory)
	{     
		bytes memory dataURI = bytes.concat(
			'{'
				'"name": "MutantBitBird #', 
                bytes(tokenId.toString()), 
                '",'
				'"description": "MutantBitBirds, Earn and Mutate",'
				'"image": "', 
                generateCharacter(tokenId), 
                '",'
				'"attributes": [', 
                    getTraitAttributes(tokenId),
                ']'
			'}'
		);
        return dataURI;	
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory)
	{       
		return string(
			bytes.concat(
				"data:application/json;base64,",
				bytes(Base64.encode(getTokenURImeta(tokenId)))
			));	
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
	  
	  function reveal() public onlyOwner {
		  _revealed = true;
	  }	  
	
    /*
    //configure royalties for Rariable
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



