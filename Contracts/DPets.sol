//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/VRFConsumerBase.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";

contract DecentraPets is ERC721URIStorage,Ownable,VRFConsumerBase,ReentrancyGuard{
    
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenId;
    
    struct Sales{
        uint256 price;
    }
    
    //contract account
    address private contractAccountAddress;
    
    //sales contract
    address private saleContractAddress;
    
    //VRF variables
    bytes32 internal keyHash;
    uint256 internal fee;
    
    //sales
    mapping(bytes32=>address) requestToUser;
    mapping(uint256=>Sales) tokenToPrice;
    mapping(address=>uint256) userToBalance;
    //minting
    mapping(uint256 =>uint256) tokenToDNA;
    
    
    //events
    event PetSale(address indexed userAddress,uint256 indexed tokenId,uint256 indexed DNA);
    event SellOnMarket(address indexed userAddress,uint256 indexed tokenId,uint256 indexed price);
    event BuyOnMarket(address indexed previousOwner,address indexed newOwner,uint256 indexed tokenId);
    
    constructor() ERC721("Decentra Pets","DPTS") VRFConsumerBase(0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,
    0x326C977E6efc84E512bB9C30f76E30c160eD06FB) {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10 ** 18; 
        contractAccountAddress = msg.sender;
    } 
    
    function setSalesContract(address salesAddress) external onlyOwner {
        saleContractAddress=salesAddress;
    }
    
    function setContractAccount(address newAddress) external onlyOwner {
        contractAccountAddress = newAddress;
    }
    
    function buyNewPet() external payable returns(bytes32){
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        require(msg.value >= 5 ether,"Contract : Need to pay at least 5 Ether");
        bytes32 requestId = requestRandomness(keyHash,fee);
        requestToUser[requestId] = msg.sender;
        userToBalance[contractAccountAddress] += msg.value;
        return requestId;
    } 
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        _tokenId.increment();
        address senderAddress = requestToUser[requestId];
        uint256 currentTokenId = _tokenId.current();
        _safeMint(senderAddress,currentTokenId);
        tokenToDNA[currentTokenId] = randomness % 10**20;
        delete requestToUser[requestId];
        emit PetSale(senderAddress,currentTokenId,tokenToDNA[currentTokenId]);
    }
    
    function getPetDNA(uint256 tokenId) external view returns(uint256){
        require(_exists(tokenId),"Contract: Token does not exist");
        return tokenToDNA[tokenId];
    }
    
    function buyFromMarket(uint256 tokenId,address toAddress) external payable {
        require(tokenToPrice[tokenId].price > 0,"Contract : Token is not on sale");
        require(msg.value >= tokenToPrice[tokenId].price,"Contract : Paid amount is less than price");
        require(ownerOf(tokenId) != toAddress,"Contract : Receiver address is the owner");
        address currentOwner = ownerOf(tokenId);
        userToBalance[currentOwner] += msg.value;
        safeTransferFrom(currentOwner,toAddress,tokenId);

        emit BuyOnMarket(currentOwner,ownerOf(tokenId),tokenId);
    }
    
    function sellOnMarket(uint256 tokenId,uint256 price) external{
        approve(saleContractAddress,tokenId);
        tokenToPrice[tokenId].price = price;
        emit SellOnMarket(msg.sender,tokenId,price);
    }
    
    function retrieveBalance() external nonReentrant {
        require(userToBalance[msg.sender] > 0,"User balance needs to be greater than 0");
        payable(msg.sender).transfer(userToBalance[msg.sender]);
        delete userToBalance[msg.sender];
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if(tokenToPrice[tokenId].price != 0){
            delete tokenToPrice[tokenId];
        }
    }
}

contract DPetsSales is Ownable{
    address internal DPetsAddress;
    
    function setDPetsAddress(address DptAddress) external onlyOwner{
        DPetsAddress = DptAddress;
    } 
    
    function purchaseFromMarket(uint256 tokenId) external payable{
        DecentraPets Dpets = DecentraPets(DPetsAddress);
        Dpets.buyFromMarket{value:msg.value}(tokenId,msg.sender);
    }
}