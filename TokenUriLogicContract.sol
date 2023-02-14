
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./Interfaces.sol";


contract TokenUriLogicContract is Ownable, ITraitChangeCost{

    using Strings for uint256;

    IMainContract public MainContract;

	//bool _revealed = false;
	//string private _contractUri = "https://rubykitties.tk/MBBcontractUri";
    //string private _baseRevealedUri = "https://rubykitties.tk/kitties/";
	//string private _baseNotRevealedUri = "https://rubykitties.tk/kitties/";
    mapping(uint256 => uint64) public TokenIdDNA;
    mapping(uint8 => TraitChangeCost) public TraitChangeCosts;    

    constructor(address maincontract)  {
	MainContract = IMainContract(maincontract);
        // setChageTraitPrice(uint8 traitId,
        //      bool allowed, uint32 changeCostEthMillis, 
        //      uint32 increaseStepCostEthMillis, uint32 decreaseStepCostEthMillis, 
        //      uint8 minValue, uint8 maxValue)
        //setChageTraitPrice(0, true, 100, 0, 0, 0, 255); // undef
        setChageTraitPrice(1, true, 0, 0, 100*1000, 0, 4); // type
        setChageTraitPrice(2, true, 0, 50*1000, 0, 0, 2); // eyes
        setChageTraitPrice(3, true, 0, 20*1000, 0, 0, 3); // beak
        setChageTraitPrice(4, true, 1*1000, 0, 0, 0, 255); // throat
        setChageTraitPrice(5, true, 1*1000, 0, 0, 0, 255); // head 
        setChageTraitPrice(6, true, 0, 1*1000, 0, 0, 255); // level
        setChageTraitPrice(7, true, 0, 1*1000, 0, 0, 255); // stamina        
	}

	function setChageTraitPrice(uint8 traitId, bool allowed, uint32 changeCostEthMillis, uint32 increaseStepCostEthMillis, uint32 decreaseStepCostEthMillis, uint8 minValue, uint8 maxValue) internal  {
        require (msg.sender == address(MainContract) || msg.sender == owner());
        require (traitId < 8, "trait err");
        TraitChangeCost memory tc = TraitChangeCost(allowed, changeCostEthMillis, increaseStepCostEthMillis, decreaseStepCostEthMillis, minValue, maxValue);
		TraitChangeCosts[traitId] = tc;
	} 

    function randInitTokenDNA(uint256 tokenId) public {
       require (msg.sender == address(MainContract));
        uint64 dnabody = uint64(((block.timestamp + block.difficulty + tokenId) % 255)<<5*8);
        uint64 dnathroat = uint64(((block.timestamp + tokenId) % 255)<<4*8);
        TokenIdDNA[tokenId] = (dnabody + dnathroat);
    }   

	function getTraitValues(uint256 tokenId) internal view returns (uint8[] memory ) {
        uint64 oldvalue = TokenIdDNA[tokenId];
        uint64 TRAIT_MASK = 255;
        uint8[] memory traits = new uint8[](8);
        for (uint i = 0; i < 8; i++) 
        {
            uint64 shift = uint64(8 * i);
            uint64 bitMask = (TRAIT_MASK << shift);
            uint64 value = ((oldvalue & bitMask) >> shift); 
            traits[i] = uint8(value);           
        }     
        return traits;   
    }

	function getTraitValue(uint256 tokenId, uint8 traitId) public view returns (uint8 ) {
        require (traitId < 8, "trait err");
		return getTraitValues(tokenId)[traitId];
	}   

    function getTraitCost(uint8 traitId) public view returns (TraitChangeCost memory) {
        require(traitId < 8, "trait err");
        return TraitChangeCosts[traitId];
	}   

	function setTraitValue(uint256 tokenId, uint8 traitId, uint8 traitValue) public {
        require (msg.sender == address(MainContract));
        require(traitId < 8, "trait err");
        uint64 newvalue = traitValue;
        newvalue = newvalue << (8 *traitId);
        uint64 oldvalue = TokenIdDNA[tokenId];
        uint64 TRAIT_MASK = 255;
        for (uint i = 0; i < 8; i++) 
        {
            if (i != traitId)
            {
                uint64 shift = uint64(8 * i);
                uint64 bitMask = TRAIT_MASK << shift;
                uint64 value = (oldvalue & bitMask); 
                newvalue |= value;
            }
        }
        TokenIdDNA[tokenId] = newvalue;        
	}	         

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
        bytes memory beakColor = 'grey';
        if (traitval == 1) beakColor = 'gold';
        else if (traitval == 2) beakColor = 'red';
        else if (traitval == 3) beakColor = 'black';
        bytes memory  basic_bird_beak_poly = "\"12,13 17,13 18,14 18,18 17,17 12,17\"";       
        return bytes.concat(
            "<polyline points=", bytes(basic_bird_beak_poly), " stroke=\"black", "\" />",
            "<polyline points=", bytes(basic_bird_beak_poly), " fill=\"", /*getRgbFromTraitVal(traitval)*/beakColor, "\" />"
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
        getBirdEyes(traits[2] != 0)
        );
    }              

	function generateCharacter(uint256 tokenId) internal view returns(bytes memory) {
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

	function getTraitAttributes(uint256 tokenId) internal view returns(bytes memory) {
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

    function tokenURI(address tokenOwner, uint256 tokenId) public view returns (string memory) {
		bytes memory dataURI = bytes.concat(
			'{'
				'"name": "MBB ', 
                bytes(MainContract.getNickName(tokenId)),     
                ' #',                           
                bytes(tokenId.toString()),
                ' owned: ',   
                bytes(MainContract.balanceOf(tokenOwner).toString()),
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

    // Opensea json metadata format interface
    function contractURI() public view returns (string memory) {       
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
            '"fee_recipient": "',
            abi.encodePacked(MainContract.getRewardContract()),
            '"'
        '}');
        return string(
			    bytes.concat(
			    "data:application/json;base64,",
				bytes(Base64.encode(dataURI)))
            //dataURI
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
}
