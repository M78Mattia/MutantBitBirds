// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./Interfaces.sol";

contract TokenUriLogicContract is Ownable, ITraitChangeCost {
    using Strings for uint256;

    IMainContract public MainContract;

    //bool _revealed = false;
    //string private _contractUri = "https://rubykitties.tk/MBBcontractUri";
    //string private _baseRevealedUri = "https://rubykitties.tk/kitties/";
    //string private _baseNotRevealedUri = "https://rubykitties.tk/kitties/";
    mapping(uint8 => TraitChangeCost) public TraitChangeCosts;    
    address public PreviousTokenUriLogicContract;
    uint16 CollectionImgTokenId;
    string private _ContractUri;
    mapping(uint16 => uint64) private _TokenIdDNA;    

    constructor(address maincontract)  Ownable(msg.sender) {
        MainContract = IMainContract(maincontract);
        PreviousTokenUriLogicContract = address(0);
        CollectionImgTokenId = 0;
        // setChageTraitPrice(uint8 traitId,
        //      bool allowed, uint32 changeCostEthMillis,
        //      uint32 increaseStepCostEthMillis, uint32 decreaseStepCostEthMillis,
        //      uint8 minValue, uint8 maxValue)
        //setChageTraitPrice(0, false, 100, 0, 0, 0, 255); // undef
        setChageTraitPrice(1, false, 0, 1000 * 1000, 0, 0, 4); // type
        setChageTraitPrice(2, false, 0, 100 * 1000, 0, 0, 2); // eyes
        setChageTraitPrice(3, false, 0, 50 * 1000, 0, 0, 3); // beak
        setChageTraitPrice(4, true, 30 * 1000, 0, 0, 0, 255); // throat
        setChageTraitPrice(5, true, 30 * 1000, 0, 0, 0, 255); // head
        setChageTraitPrice(6, false, 0, 5 * 1000, 0, 0, 255); // level
        setChageTraitPrice(7, false, 0, 5 * 1000, 0, 0, 255); // stamina
    }

    /*
    function cloneTokenUriLogic(address tokenUriLogic) external onlyOwner {
        uint16 i = 1;
        while (TokenUriLogicContract(tokenUriLogic).TokenIdDNA(i) > 0) {
            TokenIdDNA[i] = TokenUriLogicContract(tokenUriLogic).TokenIdDNA(i);
            i = i+1;
        }
    }
    */

    function setCollectionImgTokenId(uint16 collectionImgTokenId) external onlyOwner {
        CollectionImgTokenId = collectionImgTokenId;
    }    

    function setPreviousTokenUriLogicContract(address previousTokenUriLogicContract) external onlyOwner {
        PreviousTokenUriLogicContract = previousTokenUriLogicContract;
    }  

    function setContractUri(string calldata contractUri) external onlyOwner {
        _ContractUri = contractUri;    
    }  

    function getTokenIdDNA(uint16 tokenId) public view returns(uint64)
    {
        uint64 res = _TokenIdDNA[tokenId];
        if (res == 0 && PreviousTokenUriLogicContract != address(0))
            res = TokenUriLogicContract(PreviousTokenUriLogicContract).getTokenIdDNA(tokenId);
        return res;
    }

    function setChageTraitPrice(
        uint8 traitId,
        bool allowed,
        uint32 changeCostEthMillis,
        uint32 increaseStepCostEthMillis,
        uint32 decreaseStepCostEthMillis,
        uint8 minValue,
        uint8 maxValue
    ) internal {
        require(msg.sender == address(MainContract) || msg.sender == owner());
        require(traitId < 8, "trait err");
        TraitChangeCost memory tc = TraitChangeCost(
            minValue,
            maxValue,
            allowed,
            changeCostEthMillis,
            increaseStepCostEthMillis,
            decreaseStepCostEthMillis
        );
        TraitChangeCosts[traitId] = tc;
    }

    function randInitTokenDNA(uint16 tokenId) external {
        require(msg.sender == address(MainContract));
        uint256 rand = (uint256)(keccak256(abi.encodePacked(block.timestamp,msg.sender,tokenId)));
        uint32 randL32 = uint32(rand & uint64(0x00000000FFFFFFFF));
        uint32 randH32 = (uint32)((rand & uint64(0xFFFFFFFF00000000)) >> 32);
        // offset 0 undef
        // offset 1 type
        // offset 2 eyes
        // offset 3 beak
        // offset 4 throat
        // offset 5 head
        // offset 6 level
        // offset 7 stamina
        uint64 dnaeye = randL32 % 1000;
        if (dnaeye <= 47)
            dnaeye = uint64(randL32 & uint32(0x00FF0000));
        else
            dnaeye = 0;
        uint64 dnabeak = (randH32 % 1000);
        if (dnabeak <= 7) dnabeak = ((3) << (3 * 8));
        else if (dnabeak <= 47) dnabeak = ((2) << (3 * 8));
        else if (dnabeak <= 500) dnabeak = ((1) << (3 * 8));
        else dnabeak = 0;        
        uint64 dnathroat = uint64(randL32 & uint32(0x000000FF)) << (4 * 8);
        uint64 dnahead = uint64(randL32 & uint32(0x0000FF00)) << (4 * 8);
        uint64 dnatype = uint64((uint64(randL32) + uint64(randH32)) % 1000);
        if (dnatype <= 5) dnatype = ((4) << (1 * 8));
        else if (dnatype <= 40) dnatype = ((3) << (1 * 8));
        else if (dnatype <= 100) dnatype = ((2) << (1 * 8));
        else if (dnatype <= 250) dnatype = ((1) << (1 * 8));
        else dnatype = 0;        
        _TokenIdDNA[tokenId] = (dnaeye + dnabeak + dnathroat + dnahead + dnatype);
    }

    function getTraitValues(uint16 tokenId)
        internal
        view
        returns (uint8[] memory)
    {
        uint64 oldvalue = getTokenIdDNA(tokenId);
        uint64 TRAIT_MASK = 255;
        uint8[] memory traits = new uint8[](8);
        for (uint256 i = 0; i < 8; ) {
            unchecked {            
                uint64 shift = uint64(8 * i);
                uint64 bitMask = (TRAIT_MASK << shift);
                uint64 value = ((oldvalue & bitMask) >> shift);
                traits[i] = uint8(value);
                i++;
            }
        }
        return traits;
    }

    function getTraitValue(uint16 tokenId, uint8 traitId)
        public
        view
        returns (uint8)
    {
        require(traitId < 8, "trait err");
        return getTraitValues(tokenId)[traitId];
    }

    function getTraitCost(uint8 traitId)
        public
        view
        returns (TraitChangeCost memory)
    {
        require(traitId < 8, "trait err");
        return TraitChangeCosts[traitId];
    }

    function setTraitValue(
        uint16 tokenId,
        uint8 traitId,
        uint8 traitValue
    ) public {
        require(msg.sender == address(MainContract));
        require(traitId < 8, "trait err");
        uint64 newvalue = traitValue;
        newvalue = newvalue << (8 * traitId);
        uint64 oldvalue = getTokenIdDNA(tokenId);
        uint64 TRAIT_MASK = 255;
        for (uint256 i = 0; i < 8; ) {
            unchecked {
                if (i != traitId) {
                    uint64 shift = uint64(8 * i);
                    uint64 bitMask = TRAIT_MASK << shift;
                    uint64 value = (oldvalue & bitMask);
                    newvalue |= value;
                }
                i++;
            }
        }
        _TokenIdDNA[tokenId] = newvalue;
    }

    function getRgbFromTraitVal(uint8 traitval)
        internal/*public*/
        pure
        returns (bytes memory)
    {
        uint256 r = (traitval >> 5);
        r = (r * 255) / 7;
        uint256 gmask = 7; // 0x07
        uint256 g = (traitval >> 2);
        g = (g & gmask);
        g = (g * 255) / 7;
        uint256 bmask = 3; // 0x03
        uint256 b = (traitval & bmask);
        b = (b * 255) / 3;
        return
            bytes.concat(
                "rgb(",
                bytes(Strings.toString(r & 255)),
                ",",
                bytes(Strings.toString(g & 255)),
                ",",
                bytes(Strings.toString(b & 255)),
                ")"
            );
    }

    function getBirdEyes()
        internal
        pure
        returns (
            /*bool crazy*/
            bytes memory
        )
    {
        return
            bytes.concat(
                '<rect class="ew" x="275" y="200" width="40" height="40" rx="3" stroke-width="0.25%" />',
                '<rect class="ey" x="275" y="220" width="20" height="20" rx="3" stroke-width="0.25%" />',
                '<rect class="ew" x="215" y="200" width="40" height="40" rx="3" stroke-width="0.25%" />',
                '<rect class="ey" x="215" y="220" width="20" height="20" rx="3" stroke-width="0.25%" />'
            );
    }

    function getBirdLayout(uint8 shapetype, bytes memory filterRef)
        internal
        pure
        returns (bytes memory)
    {
        if (shapetype == 0) {
            // basic
            return
                bytes.concat(
                    '<path class="hd" d="M170,480l0,-90l-35,-50l0,-155l45,-69l40,-30l46,0l55,60l0,190l-5,0l0,40l-40,40l0,65" stroke-width="2%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="th" d="M193,480l0,-99l30,-45l91,0l0,39l-40,40l0,66" stroke-width="0.15%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="bk" d="M235,275l110,0l20,25l0,80l-10,-25l-120,0" stroke-width="2%" ', filterRef, '/>'
                );
        } else if (shapetype == 1) {
            // jay
            return
                bytes.concat(
                    '<path class="hd" d="M170,480 l0,-90l-35,-50l0,-155l-60,-120l140,0l20,5l80,80l6,10l0,176l-5,0l0,40l-40,40l0,65" stroke-width="2%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="th" d="M193,480l0,-99l30,-45l91,0l0,39l-40,40l0,66" stroke-width="0.15%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="bk" d="M235,275l110,0l20,25l0,80l-10,-25l-120,0" stroke-width="2%" ', filterRef, '/>'
                );
        } else if (shapetype == 2) {
            // whoodpecker
            return
                bytes.concat(
                    '<path class="hd" d="M170,480 l0,-90l-35,-50l0,-155l45,-69l40,-30l46,0l55,60l0,190l-5,0l0,40l-40,40l0,65" stroke-width="2%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="th" d="M193,480l0,-99l30,-45l91,0l0,39l-40,40l0,66" stroke-width="0.15%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="bk" d="M245,285l225,0l-20,25l-75,35l-130,0" stroke-width="2%" ', filterRef, '/>'
                );
        } else if (shapetype == 3) {
            // eagle
            return
                bytes.concat(
                    '<path class="hd" d="M170,480 l0,-90l-35,-50l0,-155l45,-69l40,-30l46,0l55,60l0,190l-5,0l0,40l-40,40l0,65" stroke-width="2%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="th" d="M172,480l0,-70l102,20l0,51" stroke-width="0.15%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="bk" d="M235,270l100,0l40,35l0,80l-20,-25l-120,0" stroke-width="2%" ', filterRef, '/>'
                );
        }
        /*if (shapetype == 4)*/
        else {
            // cockatoo
            return
                bytes.concat(
                    '<path class="hd" d="M170,480l0,-90l-35,-50l0,-115l25,-49l60,-25l60,0l41,30l0,155l-5,0l0,40l-40,40l0,65" stroke-width="0.15%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="cr" d="M321,181l0,-50l5,-50l10,-50l10,-20l0-5l-5,0l-30,10l-30,30l-12,30l-10,30l-2,25l1,-15l-30,-30l0,-50l3,-20l-10,0l-10,5l-25,35l0,70l5,20l-5,-20l-30,-10l-10,-10l-10,-30l0,-20l-10,0l-15,20l-5,30l0,20l10,20l40,40l-10,-10l-40,0l-40,-10l-5,0l0,10l20,25l20,10l20,10l14,55l20,-60l50,-45l60,-10l29,0l15,11z" stroke-width="0.15%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="th" d="M193,480l0,-99l30,-45l91,0l0,39l-40,40l0,66" stroke-width="0.15%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="ol" d="M275,481l0,-65l40,-40l0,-40l5,0l0,-205l5,-50l10,-50l10,-20l0-5l-5,0l-30,10l-30,30l-12,30l-10,30l-2,25l1,-15l-30,-30l0,-50l3,-20l-10,0l-10,5l-25,35l0,70l5,20l-5,-20l-30,-10l-10,-10l-10,-30l0,-20l-10,0l-15,20l-5,30l0,20l10,20l40,40l-10,-10l-40,0l-40,-10l-5,0l0,10l20,25l20,10l20,10l14,55l0,63l35,50l0,91M118,220l10,5" stroke-width="2%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="bk" d="M235,275l110,0l20,25l0,60l-10,-25l-20,0l-15,25l-85,0" stroke-width="2%" ', filterRef, '/>'
                );
        }
    }

    function generateCharacterFilter(uint16 ownedcount)
        internal
        pure
        returns (bytes memory)
    {
        uint256 irr = 10 + ((ownedcount > 50) ? 50 : ownedcount);
        return
            bytes.concat(
                '<filter id="sofGlow" height="300%" width="300%" x="-75%" y="-75%">', // <!--Thicken out the original shape-->
                '<feMorphology operator="dilate" radius="4" in="SourceAlpha" result="thicken"/>', // <!--Use a gaussian blur to create the soft blurriness of the glow-->
                '<feGaussianBlur in="thicken" stdDeviation="',
                bytes(irr.toString()),
                '" result="blurred"/>', // <!--Change the colour-->
                '<feFlood flood-color="rgb(0,186,255)" result="glowColor"/>', // <!--Color in the glows-->
                '<feComposite in="glowColor" in2="blurred" operator="in" result="softGlow_colored"/>', //<!--Layer the effects together-->
                '<feMerge><feMergeNode in="softGlow_colored"/> <feMergeNode in="SourceGraphic"/></feMerge>',
                "</filter>"
            );
    }

    function generateCharacterStyles(
        bool nightly,
        bytes memory eycolor,
        bytes memory ewcolor,
        bytes memory beakColor,
        bytes memory throatColor,
        bytes memory headColor
    ) internal pure returns (bytes memory) {
        //bytes memory filterRef = "";
        //if (nightly) {
        //    filterRef = bytes(';filter="url(#sofGlow)"');
        //}
        bytes memory p1 = bytes.concat(
            //<style type="text/css">.hd{fill:rgb(138,28,94);}.ew{fill:rgb(240,248,255);}.th, .cr {fill:rgb(8,32,220);}.bk{fill:rgb(152,152,152);}.ol{fill:rgba(0,0,0,0);}</style>
            '<style type="text/css">.hd{fill:',
            headColor,
            ";stroke:",
            (nightly ? headColor : bytes("black")),
            //filterRef,
            ";}.ey{fill:",
            eycolor,
            ";stroke:",
            /*nightly ? getRgbFromTraitVal(traits[5]) :*/
            bytes("black"),
            //filterRef,
            ";}.ew{fill:",
            ewcolor,
            ";stroke:",
            /*(nightly ? ewcolor : bytes("black")*/
            bytes("black")//,
            //filterRef
        );
        bytes memory p2 = bytes.concat(
            ";}.th, .cr {fill:",
            throatColor,
            ";stroke:",
            (nightly ? throatColor : bytes("black")),
            //filterRef,
            ";}.bk{fill:",
            beakColor,
            ";stroke:",
            (nightly ? beakColor : bytes("black")),
            //filterRef,
            ";}.ol{fill:rgba(0,0,0,0);}</style>"
        );
        return bytes.concat(p1, p2);
    }

    function generateCharacterSvg(
        uint16 tokenId,
        bool nightly,
        uint16 ownedcount
    ) internal view returns (bytes memory) {
        uint8[] memory traits = getTraitValues(tokenId);
        bytes memory eycolor = "rgb(0, 0, 0)";
        bytes memory ewcolor = "rgb(240,248,255)";
        if (traits[2] != 0) {
            eycolor = "rgb(154, 0, 0)";
            ewcolor = getRgbFromTraitVal(traits[2]);
        }
        bytes memory beakColor = "grey";
        if (traits[3] == 1) beakColor = "gold";
        else if (traits[3] == 2) beakColor = "red";
        else if (traits[3] == 3) beakColor = "black";
        return
            bytes.concat(
                generateCharacterStyles(
                    nightly,
                    eycolor,
                    ewcolor,
                    beakColor,
                    getRgbFromTraitVal(traits[4]),
                    getRgbFromTraitVal(traits[5])
                ),
                (nightly ? generateCharacterFilter(ownedcount) : bytes(" ")),
                getBirdLayout(getTraitValue(tokenId, 1), ((nightly) ? bytes(' filter="url(#sofGlow)" ') : bytes(" "))),
                getBirdEyes()
            );
    }

    function generateCharacter(uint16 tokenId, uint16 ownedcount, bool ignoreDayNigth)
        internal/*public*/
        view
        returns (bytes memory)
    {
        uint256 dayHour = (block.timestamp % 86400) / 3600;
        bool isNight = (ignoreDayNigth == false) && ((dayHour >= 21) || (dayHour <= 4));
        bytes memory svg = bytes.concat(
            '<?xml version="1.0" encoding="UTF-8"?>',
            '<svg x="0px" y="0px" viewBox="0 0 480 480" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" preserveAspectRatio="xMinYMin meet">',
            '<rect x="0" y="0" width="480" height="480" fill="',
            (isNight ? bytes("rgb(8,42,97)") : bytes("rgb(238,238,238)")),
            '" />',
            generateCharacterSvg(tokenId, isNight, ownedcount),
            "</svg>"
        );
        return
            bytes.concat(
                "data:image/svg+xml;base64,",
                bytes(Base64.encode(svg))
            );
    }

    function getColorMapName(uint8 colourVal)
        internal/*public*/
        pure
        returns (bytes memory)
    {
        uint8[256] memory colourList = [uint8(98), 110, 110, 66, 98, 110, 110, 66, 103, 116, 116, 66, 103, 116, 116, 66, 103, 116, 116, 97, 
                                        103, 116, 116, 97, 108, 108, 97, 97, 108, 108, 97, 97, 98, 110, 110, 66, 98, 110, 110, 66, 103, 116, 
                                        116, 66, 103, 116, 116, 66, 103, 116, 116, 97, 103, 116, 116, 97, 108, 108, 97, 97, 108, 108, 97, 97, 
                                        109, 112, 112, 66, 109, 112, 112, 66, 111, 71, 71, 66, 111, 71, 71, 66, 111, 71, 71, 97, 111, 71, 71, 
                                        97, 108, 71, 71, 97, 108, 108, 97, 97, 109, 112, 112, 66, 109, 112, 112, 66, 111, 71, 71, 66, 111, 71, 
                                        71, 71, 111, 71, 71, 115, 111, 71, 71, 115, 111, 71, 115, 115, 108, 71, 115, 97, 109, 112, 112, 102, 109, 
                                        112, 112, 102, 111, 71, 71, 102, 111, 71, 71, 115, 111, 71, 71, 115, 111, 71, 115, 115, 111, 71, 115, 115, 
                                        121, 115, 115, 115, 109, 112, 112, 102, 109, 112, 112, 102, 111, 71, 71, 102, 111, 71, 71, 115, 111, 71, 
                                        115, 115, 79, 71, 115, 115, 121, 115, 115, 115, 121, 121, 115, 119, 114, 114, 102, 102, 114, 114, 102, 102, 
                                        114, 71, 71, 102, 79, 71, 115, 115, 79, 79, 115, 115, 79, 79, 115, 115, 121, 121, 115, 119, 121, 121, 115, 
                                        119, 114, 114, 102, 102, 114, 114, 102, 102, 114, 114, 102, 102, 79, 79, 115, 102, 79, 79, 115, 115, 79, 79, 
                                        115, 119, 121, 121, 115, 119, 121, 121, 119, 119];
        if (colourList[colourVal] == 98/*'b'*/)
            return  bytes('black');
        else if (colourList[colourVal] == 110/*'n'*/)
            return  bytes('navy');         
        else if (colourList[colourVal] == 66/*'B'*/)
            return  bytes('blue');             
        else if (colourList[colourVal] == 103/*'g'*/)
            return  bytes('green');            
        else if (colourList[colourVal] == 116/*'t'*/)
            return  bytes('teal');     
        else if (colourList[colourVal] == 97/*'a'*/)
            return  bytes('aqua');  
        else if (colourList[colourVal] == 108/*'l'*/)
            return  bytes('lime');       
        else if (colourList[colourVal] == 109/*'m'*/)
            return  bytes('maroon');     
        else if (colourList[colourVal] == 112/*'p'*/)
            return  bytes('purple');    
        else if (colourList[colourVal] == 111/*'o'*/)
            return  bytes('olive');              
        else if (colourList[colourVal] == 71/*'G'*/)
            return  bytes('gray');    
        else if (colourList[colourVal] == 115/*'s'*/)
            return  bytes('silver');      
        else if (colourList[colourVal] == 102/*'f'*/)
            return  bytes('fuchsia');     
        else if (colourList[colourVal] == 121/*'y'*/)
            return  bytes('yellow');    
        else if (colourList[colourVal] == 79/*'O'*/)
            return  bytes('orange');      
        else if (colourList[colourVal] == 119/*'w'*/)
            return  bytes('white'); 
        else if (colourList[colourVal] == 114/*'r'*/)
            return  bytes('red');                                                                                                                                                 
        return  bytes('none');
    }

    function getTraitAttributesTType(uint8 traitId, uint8 traitVal)
        internal/*public*/
        pure
        returns (bytes memory)
    {
        bytes memory traitName;
        bytes memory traitValue = bytes(Strings.toString(traitVal));
        if (traitId == 0) { 
            traitName = "tr-0";
        }
        else if (traitId == 1) { 
            traitName = "type";
            if (traitVal == 0) traitValue = "basic"; 
            else if (traitVal == 1) traitValue = "jay";
            else if (traitVal == 2) traitValue = "whoodpecker";
            else if (traitVal == 3) traitValue = "eagle";
            else /*if (traitVal == 4)*/ traitValue = "cockatoo";
        }
        else if (traitId == 2) { 
            traitName = "eyes";
            if (traitVal == 0) traitValue = "normal";
            else traitValue = "crazy";
        }
        else if (traitId == 3) { 
            traitName = "beak";
            //traitValue = getColorMapName(traitVal);
            if (traitVal == 0) traitValue = "grey";
            else if (traitVal == 1) traitValue = "gold";
            else if (traitVal == 2) traitValue = "red";
            else /*if (traitVal == 3)*/ traitValue = "black";         
        }
        else if (traitId == 4) { 
            traitName = "throat";
            traitValue = getColorMapName(traitVal);
        }
        else if (traitId == 5) { 
            traitName = "head";
            traitValue = getColorMapName(traitVal);
        }
        else if (traitId == 6) { 
            traitName = "level";
        }
        else if (traitId == 7) { 
            traitName = "stamina";
        }
        bytes memory display;
        if (traitId == 7) display = '"display_type": "boost_number",';
        else if (traitId == 6) display = '"display_type": "number",';
        else display = "";
        return
            bytes.concat(
                "{",
                display,
                '"trait_type": "',
                traitName,
                '","value": "',
                traitValue,
                '"}'
            );
    }

    function getTraitAttributes(uint16 tokenId)
        internal/*public*/
        view
        returns (bytes memory)
    {
        uint8[] memory traits = getTraitValues(tokenId);
        /*string memory attribs;
        for (uint8 i = 0; i < 8; i++) 
        {
            attribs = string.concat(attribs, getTraitAttributesTType(i, traits[i]));                        
        }
        return attribs;*/
        return
            bytes.concat(
                //getTraitAttributesTType(0, traits[0]),
                //",",
                getTraitAttributesTType(1, traits[1]),
                ",",
                getTraitAttributesTType(2, traits[2]),
                ",",
                getTraitAttributesTType(3, traits[3]),
                ",",
                getTraitAttributesTType(4, traits[4]),
                ",",
                getTraitAttributesTType(5, traits[5]),
                ",",
                getTraitAttributesTType(6, traits[6]),
                ",",
                getTraitAttributesTType(7, traits[7])
            );
    }

    function tokenURI(address tokenOwner, uint16 tokenId)
        external
        view
        returns (string memory)
    {
        uint256 id256 = tokenId;
        bytes memory tokenNickName = bytes(MainContract.getNickName(tokenId));
        bytes memory dataURI = bytes.concat(
            "{"
            '"name": "',
            ((tokenNickName.length > 0) ? bytes(tokenNickName) :  bytes("MBB")),
            " #",
            bytes(id256.toString()),
            //' owned: ',
            //bytes(MainContract.balanceOf(tokenOwner).toString()),
            '",'
            '"description": "MutantBitBirds, Earn and Mutate",'
            '"image": "',
            generateCharacter(tokenId, (uint16)(MainContract.balanceOf(tokenOwner)), false),
            '",'
            '"attributes": [',
            getTraitAttributes(tokenId),
            "]"
            "}"
        );
        return
            string(
                bytes.concat(
                    "data:application/json;base64,",
                    bytes(Base64.encode(dataURI))
                )
            );
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    // Opensea json metadata format interface
    function contractURI() external view returns (string memory) {
        bytes memory c = bytes(_ContractUri);
        if (c.length > 0)
            return _ContractUri;
        uint16 ctid = ((CollectionImgTokenId == 0) ? ((_TokenIdDNA[1] > 0) ? 1 : 0) : CollectionImgTokenId);
        bytes memory dataURI = bytes.concat(
            "{",
            '"name": "MutantBitBirds",',
            '"description": "Earn MutantCawSeeds (MCS) and customize your MutantBitBirds !",',
            //'"image": "',
            //bytes(_contractUri),
            //'/image.png",',
            '"image": "',
            (ctid == 0) ? bytes("") : generateCharacter(ctid, 0, true),            
            //'"external_link": "',
            //bytes(_contractUri),
            '"',
            '"fee_recipient": "',
            bytes(toString(abi.encodePacked(MainContract.getRewardContract()))),
            '"'
            "}"
        );
        return
            string(
                bytes.concat(
                    "data:application/json;base64,",
                    bytes(Base64.encode(dataURI))
                )
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
