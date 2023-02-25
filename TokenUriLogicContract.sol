// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./Interfaces.sol";

contract TokenUriLogicContract is Ownable, ITraitChangeCost {
    using Strings for uint256;

    IMainContract public MainContract;

    //bool _revealed = false;
    //string private _contractUri = "https://rubykitties.tk/MBBcontractUri";
    //string private _baseRevealedUri = "https://rubykitties.tk/kitties/";
    //string private _baseNotRevealedUri = "https://rubykitties.tk/kitties/";
    mapping(uint256 => uint64) public TokenIdDNA;
    mapping(uint8 => TraitChangeCost) public TraitChangeCosts;

    constructor(address maincontract) {
        MainContract = IMainContract(maincontract);
        // setChageTraitPrice(uint8 traitId,
        //      bool allowed, uint32 changeCostEthMillis,
        //      uint32 increaseStepCostEthMillis, uint32 decreaseStepCostEthMillis,
        //      uint8 minValue, uint8 maxValue)
        //setChageTraitPrice(0, true, 100, 0, 0, 0, 255); // undef
        setChageTraitPrice(1, true, 0, 100 * 1000, 0, 0, 4); // type
        setChageTraitPrice(2, true, 0, 50 * 1000, 0, 0, 2); // eyes
        setChageTraitPrice(3, true, 0, 20 * 1000, 0, 0, 3); // beak
        setChageTraitPrice(4, true, 1 * 1000, 0, 0, 0, 255); // throat
        setChageTraitPrice(5, true, 1 * 1000, 0, 0, 0, 255); // head
        setChageTraitPrice(6, true, 0, 1 * 1000, 0, 0, 255); // level
        setChageTraitPrice(7, true, 0, 1 * 1000, 0, 0, 255); // stamina
    }

    function cloneTokenUriLogic(address tokenUriLogic) external onlyOwner {
        uint256 i = 1;
        while (TokenUriLogicContract(tokenUriLogic).TokenIdDNA(i) > 0) {
            TokenIdDNA[i] = TokenUriLogicContract(tokenUriLogic).TokenIdDNA(i);
            i = i+1;
        }
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

    function randInitTokenDNA(uint256 tokenId) external {
        require(msg.sender == address(MainContract));
        uint64 dnaeye = uint64((block.timestamp * tokenId) % 1000);
        if (dnaeye <= 47)
            dnaeye = uint64(((block.timestamp * tokenId) % 1000) << (2 * 8));
        else dnaeye = 0;
        uint64 dnabeak = uint64((block.timestamp * tokenId) % 1000);
        if (dnabeak <= 7) dnabeak = ((3) << (3 * 8));
        else if (dnabeak <= 47) dnabeak = ((2) << (3 * 8));
        else if (dnabeak <= 500) dnabeak = ((1) << (3 * 8));
        else dnabeak = 0;
        uint64 dnathroat = uint64(
            ((block.timestamp + tokenId) % 255) << (4 * 8)
        );
        uint64 dnahead = uint64(
            ((block.timestamp + block.difficulty + tokenId) % 255) << (5 * 8)
        );
        TokenIdDNA[tokenId] = (dnaeye + dnabeak + dnathroat + dnahead);
    }

    function getTraitValues(uint256 tokenId)
        internal
        view
        returns (uint8[] memory)
    {
        uint64 oldvalue = TokenIdDNA[tokenId];
        uint64 TRAIT_MASK = 255;
        uint8[] memory traits = new uint8[](8);
        for (uint256 i = 0; i < 8; i++) {
            uint64 shift = uint64(8 * i);
            uint64 bitMask = (TRAIT_MASK << shift);
            uint64 value = ((oldvalue & bitMask) >> shift);
            traits[i] = uint8(value);
        }
        return traits;
    }

    function getTraitValue(uint256 tokenId, uint8 traitId)
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
        uint256 tokenId,
        uint8 traitId,
        uint8 traitValue
    ) public {
        require(msg.sender == address(MainContract));
        require(traitId < 8, "trait err");
        uint64 newvalue = traitValue;
        newvalue = newvalue << (8 * traitId);
        uint64 oldvalue = TokenIdDNA[tokenId];
        uint64 TRAIT_MASK = 255;
        for (uint256 i = 0; i < 8; i++) {
            if (i != traitId) {
                uint64 shift = uint64(8 * i);
                uint64 bitMask = TRAIT_MASK << shift;
                uint64 value = (oldvalue & bitMask);
                newvalue |= value;
            }
        }
        TokenIdDNA[tokenId] = newvalue;
    }

    function getRgbFromTraitVal(uint8 traitval)
        internal
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

    function generateCharacterFilter(uint256 ownedcount)
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
        uint256 tokenId,
        bool nightly,
        uint256 ownedcount
    ) internal view returns (bytes memory) {
        uint8[] memory traits = getTraitValues(tokenId);
        bytes memory eycolor = "rgb(0, 0, 0)";
        bytes memory ewcolor = "rgb(240,248,255)";
        if (traits[2] == 1) {
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

    function generateCharacter(uint256 tokenId, uint256 ownedcount)
        internal
        view
        returns (bytes memory)
    {
        uint256 dayHour = (block.timestamp % 86400) / 3600;
        bool isNight = ((dayHour >= 21) || (dayHour <= 4));
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

    function getTraitAttributesTType(uint8 traitId, uint8 traitVal)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory traitName;
        if (traitId == 0) traitName = "tr-0";
        else if (traitId == 1) traitName = "type";
        else if (traitId == 2) traitName = "eyes";
        else if (traitId == 3) traitName = "beak";
        else if (traitId == 4) traitName = "throat";
        else if (traitId == 5) traitName = "head";
        else if (traitId == 6) traitName = "level";
        else if (traitId == 7) traitName = "stamina";
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
                bytes(Strings.toString(traitVal)),
                '"}'
            );
    }

    function getTraitAttributes(uint256 tokenId)
        internal
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
                getTraitAttributesTType(0, traits[0]),
                ",",
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

    function tokenURI(address tokenOwner, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        bytes memory dataURI = bytes.concat(
            "{"
            '"name": "MBB ',
            bytes(MainContract.getNickName(tokenId)),
            " #",
            bytes(tokenId.toString()),
            //' owned: ',
            //bytes(MainContract.balanceOf(tokenOwner).toString()),
            '",'
            '"description": "MutantBitBirds, Earn and Mutate",'
            '"image": "',
            generateCharacter(tokenId, MainContract.balanceOf(tokenOwner)),
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

    // Opensea json metadata format interface
    function contractURI() external view returns (string memory) {
        bytes memory dataURI = bytes.concat(
            "{",
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
