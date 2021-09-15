//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/VRFConsumerBase.sol";

contract DecentraPets is ERC721URIStorage,Ownable,VRFConsumerBase{
    
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenId;
    
    //sales contract
    address private saleContractAddress;
    
    //VRF variables
    bytes32 internal keyHash;
    uint256 internal fee;
    
    //sales
    mapping(bytes32=>address) requestToUser;
    
    constructor() ERC721("Decentra Pets","DPTS") VRFConsumerBase(0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,
    0x326C977E6efc84E512bB9C30f76E30c160eD06FB) {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10 ** 18; 
    } 
    
    function setSalesContract(address salesAddress) external onlyOwner {
        saleContractAddress=salesAddress;
    }
    
    function buyNewPet() external payable returns(bytes32){
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 requestId = requestRandomness(keyHash,fee);
        requestToUser[requestId] = msg.sender;
        return requestId;
    } 
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        _tokenId.increment();
        uint256 randomResult = randomness;
        //Define pet genes
    }
    
    function buyFromMarket(uint256 tokenId) external payable {
        //resale 
    }
    
}

contract DPetsSales is Ownable{
    address internal DPetsAddress;
    
    function setDPetsAddress(address DptAddress) external onlyOwner{
        DPetsAddress = DptAddress;
    } 
    
    function purchaseFromMarket(uint256 tokenId) external payable{
        DecentraPets Dpets = DecentraPets(DPetsAddress);
        Dpets.buyFromMarket{value:msg.value}(tokenId);
    }
}