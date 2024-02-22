// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

contract HoneyGenesis is ERC1155, IERC2981 {
    address private owner;
    uint256 public totalSupply;
    uint256 private constant TOTAL_SUPPLY_CAP = 6000;
    uint256 private constant INITIAL_PRICE = 0.07 ether;
    uint256 private constant PRICE_INCREMENT = 0.007 ether;
    uint256 private constant INITIAL_SUPPLY_LIMIT = 1000;
    uint256 private constant SUPPLY_INCREMENT_LIMIT = 500;

    // Static URL for all NFTs
    string private constant BASE_URI = "https://media.istockphoto.com/id/1486357598/photo/coastal-brown-bear-fishing-in-katmai.jpg?s=1024x1024&w=is&k=20&c=CDXisI1NFpmH4oD-TmWVgGCfDUUuoS9jRu_kzzPCe0g=";

    constructor() ERC1155(BASE_URI) {
        owner = msg.sender;
        totalSupply = 0; // Initialize total supply
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function mint(uint256 id, uint256 amount) public payable {
        require(totalSupply + amount <= TOTAL_SUPPLY_CAP, "Exceeds total supply cap");
        uint256 currentPrice = getCurrentPrice();
        require(msg.value >= amount * currentPrice, "Ether sent is not correct");

        _mint(msg.sender, id, amount, "");
        totalSupply += amount;
    }

    function getCurrentPrice() public view returns (uint256) {
        if(totalSupply < INITIAL_SUPPLY_LIMIT) {
            return INITIAL_PRICE;
        } else {
            uint256 priceIncrements = (totalSupply - INITIAL_SUPPLY_LIMIT) / SUPPLY_INCREMENT_LIMIT + 1;
            return INITIAL_PRICE + (priceIncrements * PRICE_INCREMENT);
        }
    }

    function getMintedNFTsCount() public view returns (uint256) {
        return totalSupply;
    }

    function getNextNFTPrice() public view returns (uint256) {
        uint256 nextTotalSupply = totalSupply + 1;
        if(nextTotalSupply <= TOTAL_SUPPLY_CAP) {
            if(nextTotalSupply <= INITIAL_SUPPLY_LIMIT) {
                return INITIAL_PRICE;
            } else {
                uint256 priceIncrements = (nextTotalSupply - INITIAL_SUPPLY_LIMIT - 1) / SUPPLY_INCREMENT_LIMIT + 1;
                return INITIAL_PRICE + (priceIncrements * PRICE_INCREMENT);
            }
        } else {
            revert("Max supply reached");
        }
    }

    // Override for royalty info to always return the owner as the receiver
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = owner; // Royalties always go to the owner
        royaltyAmount = salePrice * 5 / 100; // Assuming a flat 5% royalty
        return (receiver, royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function uri(uint256) public view override returns (string memory) {
        return BASE_URI;
    }
}
