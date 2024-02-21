// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import "lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

contract HoneyGenesis is ERC1155, IERC2981 {
    address private owner;
    uint256 private constant MINT_ROYALTY = 8;
    uint256 private constant SECONDARY_SALE_ROYALTY = 5;

    // Mapping from tokenID to creator
    mapping(uint256 => address) private creators;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC1155("") {
        owner = msg.sender;
    }

    // Ensure only the contract owner can mint new tokens
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Minting function with royalty logic on mint
    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        _mint(account, id, amount, data);
        creators[id] = msg.sender; // Set the creator for royalty info

        // Implement logic here to handle the 8% royalty on mint if applicable
        // This could involve setting aside tokens or funds in a specific way
    }

    // Override for royalty info (EIP-2981)
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(creators[tokenId] != address(0), "Token does not exist");
        receiver = creators[tokenId];
        // Differentiate first sale from secondary sales
        // This example assumes the contract can differentiate minting (first sale) from secondary sales
        // You might need a custom mechanism to track first versus secondary sales
        royaltyAmount = salePrice * SECONDARY_SALE_ROYALTY / 100;
        return (receiver, royaltyAmount);
    }

    // Supports interface function (including IERC2981)
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // Custom function to set token URI if desired (not part of ERC-1155 standard, but often included)
    function setURI(uint256 tokenId, string memory uri) public onlyOwner {
        require(bytes(_tokenURIs[tokenId]).length == 0, "URI already set");
        _tokenURIs[tokenId] = uri;
        emit URI(uri, tokenId);
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        return _tokenURIs[tokenId];
    }
}
