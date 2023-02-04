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
    mapping(uint256 => string) public _tokenIdNickName;
	string private _contractUri = "https://rubykitties.tk/MBBcontractUri";
    //string private _baseRevealedUri = "https://rubykitties.tk/kitties/";
	//string private _baseNotRevealedUri = "https://rubykitties.tk/kitties/";
	uint16 private _maxTotalSupply; 
	uint16 private _currentReserveSupply;        
	uint16 private _mintMaxTotalBalance = 5;
	uint256 private _mintTokenPriceEth = 50000000000000000; // 0.050 ETH
	//bool _revealed = false;
	bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /*
    <?xml version="1.0"?>
    <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><rect x="0" y="0" width="24" height="24" fill="white" />
    <polyline points="8,23 8,19 7,18 6,17 6,9 7,8 7,7 8,6 9,5 10,5 11,4 12,4 13,5 14,6 15,7 15,18 14,19 13,20 13,23" stroke="black" />
    <polyline points="8,23 8,19 7,18 6,17 6,9 7,8 7,7 8,6 9,5 10,5 11,4 12,4 13,5 14,6 15,7 15,18 14,19 13,20 13,23" fill="pink" />
    <polyline points="9,23 9,18 10,17 11,16 15,14 15,17 15,18 14,19 13,20 13,23" fill="blue" /> 
    <polyline points="12,13 17,13 18,14 18,18 17,17 12,17" stroke="black" /> 
    <polyline points="12,13 17,13 18,14 18,18 17,17 12,17" fill="gold" />
    <rect x="10" y="10" width="2" height="2" fill="white" />
    <rect x="13" y="10" width="2" height="2" fill="white" /> 
    <rect x="10" y="11" width="1" height="1" fill="red" />
    <rect x="13" y="11" width="1" height="1" fill="red" /> 
    </svg>
    */   
     

    constructor(uint16 maxTotalSupply, uint16 reserveSupply) ERC721("MutantBitBirds", "MTB") {
        require(maxTotalSupply > 0, "err supply");
	    require(reserveSupply < maxTotalSupply, "err reserve");
        _maxTotalSupply = maxTotalSupply;
        _currentReserveSupply = reserveSupply;
		_setDefaultRoyalty(msg.sender, 850);
	    reserveMint(msg.sender, 1);
	}

    // Opensea json metadata format interface
    function contractURI() public pure returns (string memory) {
        bytes memory dataURI = bytes.concat(
        '{',
            '"name": "MutantBitBirds",',
            '"description": "Earn MutantCawSeeds (MCS) and customize your MutantBitBirds !",',
            //'"image": "', 
            //bytes(_contractUri), 
            //'/image.png",',
            //'"external_link": "',
            //bytes(_contractUri),
            '"',
        '}');
        return string(
			bytes.concat(
				"data:application/json;base64,",
				bytes(Base64.encode(dataURI))
        ));
    }

    function setContractURI(string calldata contractUri) external onlyOwner() {
		_contractUri = contractUri;
	}
	
    function internalMint(address to) internal {
		require(_tokenIdCounter.current() < _maxTotalSupply, "max supply");	
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        uint256 dnabody = ((block.timestamp + block.difficulty + _tokenIdCounter.current()) % 255)<<5*8;
        uint256 dnathroat = ((block.timestamp + _tokenIdCounter.current()) % 255)<<4*8;
		_tokenIdDNA[tokenId] = (dnabody + dnathroat);
		//setRoyalties(tokenId, owner(), 1000);
    }	

    function reserveMint(address to, uint16 quantity) public onlyOwner {
        require(quantity > 0, "cannot be zero");
        require(_currentReserveSupply >= quantity, "no reserve");
        _currentReserveSupply = _currentReserveSupply -quantity;
        for (uint i = 0; i < quantity; i++) 
		    internalMint(to);
    }
	
	function publicMint(uint16 quantity) external payable {
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
	
    /*
	function setBaseRevealedUri(string calldata baseUri) external onlyOwner() {
		_baseRevealedUri = baseUri;
	}
	
	function setBaseNotRevealedUri(string calldata baseUri) external onlyOwner() {
		_baseNotRevealedUri = baseUri;
	}	
    */

	function setTokenPriceEth(uint256 tokenPriceEth) external onlyOwner() {
		_mintTokenPriceEth = tokenPriceEth;
	}

	function getTokenPriceEth() public view returns (string memory) {
		return _mintTokenPriceEth.toString();
	}	

    /*
	function setMaxTotalSupply(uint256 maxTotalSupply) external onlyOwner() {
		_maxTotalSupply = maxTotalSupply;
	}
    */

    function getCurrentReserveSupply() public view returns (string memory){
        return Strings.toString(_currentReserveSupply);
    }

    function getMaxTotalSupply() public view returns (string memory){
        return Strings.toString(_maxTotalSupply);
    }

	function setMintTokenPriceEth(uint256 mintTokenPriceEth) external onlyOwner() {
		_mintTokenPriceEth = mintTokenPriceEth;
	}

    function getMintTokenPriceEth() public view returns (string memory){
        return _mintTokenPriceEth.toString();
    }  
    
 	function setMintMaxTotalBalance(uint16 mintMaxTotalBalance) external onlyOwner() {
		_mintMaxTotalBalance = mintMaxTotalBalance;
	}

    function getMintMaxTotalBalance() public view returns (string memory){
        return Strings.toString(_mintMaxTotalBalance);
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
        uint256 TRAIT_MASK = 255;
        uint8[] memory traits = new uint8[](8);
        for (uint i = 0; i < 8; i++) 
        {
            uint256 bitMask = TRAIT_MASK << (8 * i);
            uint256 value = (oldvalue & bitMask) >> (8 * i); 
            traits[i] = uint8(value);           
        }     
        return traits;   
    }

    function getNicknName(uint256 tokenId) public view returns (string memory ) {
         require(_exists(tokenId), "token err");
         return string(_tokenIdNickName[tokenId]);
    }

	function getTraitValue(uint256 tokenId, uint8 traitId) public view returns (uint8 ) {
        require (traitId < 8, "trait err");
        require(_exists(tokenId), "token err");
		return getTraitValues(tokenId)[traitId];
	}

    function validateNickName(string memory str) public pure returns (bool){
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
	function setNickName(uint256 tokenId, string calldata nickname) public {
        require(_exists(tokenId), "token err");
        require(ownerOf(tokenId) == msg.sender, "no owner");
        require(validateNickName(nickname), "refused");
        _tokenIdNickName[tokenId] = nickname;
    }    

	function setTraitValue(uint256 tokenId, uint8 traitId, uint8 traitValue) public {
        require (traitId < 8, "trait err");
        require(_exists(tokenId), "token err");
        require(ownerOf(tokenId) == msg.sender, "no owner");
        uint256 newvalue = traitValue;
        newvalue = newvalue << (8 *traitId);
        uint256 oldvalue = _tokenIdDNA[tokenId];
        uint256 TRAIT_MASK = 255;
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
	
	/*
    function getImages(uint256 tokenId) public view returns (string memory) {
		if(_revealed == false) {
			return string(abi.encodePacked(_baseNotRevealedUri, tokenId.toString(), ".png"));
		}	
		return string(abi.encodePacked(_baseRevealedUri, tokenId.toString(), ".png"));
	}
    */	
    function getRgbFromTraitVal(uint8 traitval) internal pure returns (bytes memory) {
        uint r = (traitval >> 5);
        r = (r * 255) / 7;
        uint gmask = 7; // 0x07
        uint g = (traitval >> 2);
        g = (g & gmask);
        g = (g * 255) / 7;
        uint bmask = 3; // 0x03
        uint b = (traitval & bmask);
        b = (b * 255) / 3;
        return bytes.concat(
                                'rgb(',
                                bytes(Strings.toString(r & 255)), 
                                ',', 
                                bytes(Strings.toString(g & 255)), 
                                ',', 
                                bytes(Strings.toString(b & 255)), 
                                ')');
    }    	

    function getBasicBirdHead(uint8 traitval) internal pure returns (bytes memory) {
        bytes memory basic_bird_shape_poly = "\"8,23 8,19 7,18 6,17 6,9 7,8 7,7 8,6 9,5 10,5 11,4 12,4 13,5 14,6 15,7 15,18 14,19 13,20 13,23\"";
        return bytes.concat(
            "<polyline points=", bytes(basic_bird_shape_poly), " stroke=\"black", "\" />",
            "<polyline points=", bytes(basic_bird_shape_poly), " fill=\"", getRgbFromTraitVal(traitval), "\" />"
            );
    } 

    function getBasicBirdThroat(uint8 traitval) internal pure returns (bytes memory) {
        bytes memory  basic_bird_throat_poly = "\"9,23 9,18 10,17 11,16 15,14 15,17 15,18 14,19 13,20 13,23\"";        
        return bytes.concat(
            "<polyline points=", bytes(basic_bird_throat_poly), " fill=\"", getRgbFromTraitVal(traitval), "\" />"
        );
    } 
   
   function getBasicBirdBeak( uint8 traitval) internal pure returns (bytes memory) {
        bytes memory  basic_bird_beak_poly = "\"12,13 17,13 18,14 18,18 17,17 12,17\"";       
        return bytes.concat(
            "<polyline points=", bytes(basic_bird_beak_poly), " stroke=\"black", "\" />",
            "<polyline points=", bytes(basic_bird_beak_poly), " fill=\"", getRgbFromTraitVal(traitval), "\" />"
        );
    }  
    
   function getBirdEyes(bool crazy) internal pure returns (bytes memory) {
        bytes memory  eyes_poly = "<rect x=\"10\" y=\"10\" width=\"2\" height=\"2\" fill=\"white\" /><rect x=\"13\" y=\"10\" width=\"2\" height=\"2\" fill=\"white\" />";
        bytes memory  eyes_dot = "<rect x=\"10\" y=\"11\" width=\"1\" height=\"1\" fill=\"black\" /><rect x=\"13\" y=\"11\" width=\"1\" height=\"1\" fill=\"black\" />";
        bytes memory  eyes_dot_crazy = "<rect x=\"10\" y=\"11\" width=\"1\" height=\"1\" fill=\"red\" /><rect x=\"13\" y=\"11\" width=\"1\" height=\"1\" fill=\"red\" />";
        if (crazy)
            return bytes.concat(bytes(eyes_poly), bytes(eyes_dot_crazy));
        return bytes.concat(bytes(eyes_poly), bytes(eyes_dot));
    }  

   function generateCharacterSvg(uint256 tokenId) internal view returns (bytes memory) {
       uint8[] memory traits = getTraitValues(tokenId);        
         /*
        Red   = (Color >> 5) * 255 / 7
        Green = ((Color >> 2) & 0x07) * 255 / 7
        Blue  = (Color & 0x03) * 255 / 3
        */ 
        return bytes.concat(
        getBasicBirdHead(traits[5]),
        getBasicBirdThroat(traits[4]),
        getBasicBirdBeak(traits[3]),
        getBirdEyes(false)
        );
    }              

	function generateCharacter(uint256 tokenId) public view returns(bytes memory){
 		bytes memory svg = bytes.concat(
		/*	'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" preserveAspectRatio="xMinYMin meet" viewBox="0 0 250 250">',
			'<style>.base { fill: white; font-family: serif; font-size: 14px; }</style>',
			'<rect width="100%" height="100%" fill="black" />',
			'<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">', 
            getTraitText(tokenId),        
            '</text>',
			'<image x="0" y="0" width="100" height="100" xlink:href="', 
            bytes(getImages(tokenId)), 
            '" />',
			'</svg>'
        */
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" preserveAspectRatio="xMinYMin meet">',
        '<rect x="0" y="0" width="24" height="24" fill="rgb(238,238,238)" />',
        generateCharacterSvg(tokenId),
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
        virtual override(ERC721)
        returns (string memory)
    {
        //return super.tokenURI(tokenId);
		bytes memory dataURI = bytes.concat(
			'{'
				'"name": "MBB ', 
                bytes(getNicknName(tokenId)),     
                ' #',                           
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
        return string(
			bytes.concat(
				"data:application/json;base64,",
				bytes(Base64.encode(dataURI))
		));
    }	
	
    function getTraitAttributesTType(uint8 traitId, uint8 traitVal) internal pure returns (bytes memory) {
        bytes memory traitName;
        if (traitId == 0)
        traitName = "tr-0";
        else if (traitId == 1)
        traitName = "type";
        else if (traitId == 2)
        traitName = "eyes";
        else if (traitId == 3)
        traitName = "beak";
        else if (traitId == 4)
        traitName = "throat";
        else if (traitId == 5)
        traitName = "head";  
        else if (traitId == 6)
        traitName = "level";
        else if (traitId == 7)
        traitName = "stamina"; 
        bytes memory display; 
        if (traitId == 7)
        display = "\"display_type\": \"boost_number\",";
        else if (traitId == 6)
        display = "\"display_type\": \"number\",";
        else
        display = "";                                                   
        return bytes.concat("{", display, "\"trait_type\": \"", traitName, "\",\"value\": \"", bytes(Strings.toString(traitVal)), "\"}");
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
				getTraitAttributesTType(0, traits[0]),',',
				getTraitAttributesTType(1, traits[1]),',',
                getTraitAttributesTType(2, traits[2]),',',
                getTraitAttributesTType(3, traits[3]),',',
                getTraitAttributesTType(4, traits[4]),',',
                getTraitAttributesTType(5, traits[5]),',',
                getTraitAttributesTType(6, traits[6]),',',
                getTraitAttributesTType(7, traits[7])
			);	        
    }
	
    /*function getTraitTextTSpan(uint8 traitId, uint8 traitVal) internal view returns (bytes memory) {
        return bytes.concat("<tspan x=\"50%\" dy=\"15\">", bytes(_traitNames[traitId]), ": ", bytes(Strings.toString(traitVal)), "</tspan>");
    }*/

	/*
    function getTraitText(uint256 tokenId) internal view returns (bytes memory) {
        uint8[] memory traits = getTraitValues(tokenId);        
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
    */    

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


