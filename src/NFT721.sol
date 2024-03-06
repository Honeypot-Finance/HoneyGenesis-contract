// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
// import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract HoneyGenesis is ERC721, IERC2981, Ownable {

    event NFTMinted(address indexed minter, uint256 amount, uint256 value);
    event FundWithdrawn(address owner, uint256 amount);

    uint256 private constant TOTAL_SUPPLY_CAP = 5000; // max 5000 NFTs
    uint256 private constant VIP_SUPPLY_CAP = 1000; // max 1000 NFTs for VIP minting

    uint256 private constant MINT_VIP_PRICE = 0.069 ether; // 0.069 ETH minting fee for VIP
    uint256 private constant MINT_UNIT_PRICE = 0.07 ether; // 0.07 ETH minting fee for normal wallets
    uint256 private constant PRICE_INCREMENT = 0.007 ether; // 0.007 ETH price increment

    uint256 private constant SUPPLY_INCREMENT_STEPSIZE = 500; // After the first 1000 NFTs, the price will increase every 500 NFTs
    uint256 private constant MAX_MINT_AMOUNT = 20; // Max 20 NFTs for each normal wallets


    uint256 public tokenId; // Token Index tracker to keep track of the entire ERC721 Collection
    uint256 public tokenCountNormal; // Token Index to keep track of public sale
    uint256 public tokenCountVIP; // Token Index to keep track of the Priority mint

    error Overflow();

    // mapping(address => uint256) private _alreadyMinted; // whitelisted wallets can only mint once at low price
    mapping(address => uint256) private _VIPMintQuota; // whitelisted wallets can only mint up to a quota at VIP price

    constructor() ERC721("HoneyGenesis", "HONEY") Ownable(msg.sender) {
        tokenId = 0;
        tokenCountNormal = 0;
        tokenCountVIP = 0;
    }

    function mint(uint256 amount) public payable {
        address minter = msg.sender;
        require(msg.value >= amount * getCurrentPrice(), "Insufficient funds");
        require(tokenId + amount <= TOTAL_SUPPLY_CAP, "Exceeds total supply cap");
        require(amount <= MAX_MINT_AMOUNT, "Exceeds max mint amount");

        for (uint256 i = 0; i < amount;) {
            ++tokenCountNormal;
            ++tokenId;
            _safeMint(minter, tokenId);
            // cannot realistically overflow on human timescales
            unchecked {
                    ++i;
            }
        }

        emit NFTMinted(minter, amount, msg.value);
    }

    function mintVIP(uint256 amount) public payable {
        // require(merkleRoot != bytes32(0), "White listing not supported");
        address minter = msg.sender;
        // bytes32 leaf = keccak256(abi.encodePacked(minter));
        // require(MerkleProof.verify(proofs, merkleRoot, leaf), "Invalid proof, sender is not on VIP whitelist");
        require(msg.value >= amount * MINT_VIP_PRICE, "Insufficient funds");
        require(tokenId + amount <= VIP_SUPPLY_CAP, "Exceeds total VIP supply cap");
        require(_VIPMintQuota[minter] >= amount, "Exceeds VIP mint quota");


        _VIPMintQuota[minter] -= amount;

        for (uint256 i = 0; i < amount;) {
            ++tokenId;
            ++tokenCountVIP;
            _safeMint(minter, tokenId);
            // cannot realistically overflow on human timescales
            unchecked {
                    ++i;
            }
        }

        emit NFTMinted(minter, amount, msg.value);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed");

        emit FundWithdrawn(owner(), address(this).balance);
    }

    // function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    //     merkleRoot = _merkleRoot;
    // }

    function getCurrentPrice() public view returns (uint256) {
        _calcPrice(tokenCountNormal);
    }

    function getNextNFTPrice() public view returns (uint256) {
        uint256 nexttokenId = tokenCountNormal + SUPPLY_INCREMENT_STEPSIZE;
        if (nexttokenId > TOTAL_SUPPLY_CAP) {
            revert Overflow();
        }
        _calcPrice(nexttokenId);

    }

    function _calcPrice(uint256 priceParam) private view returns (uint256) {
        uint256 priceIncrements = priceParam / SUPPLY_INCREMENT_STEPSIZE + 1;
        return MINT_UNIT_PRICE + (priceIncrements * PRICE_INCREMENT);

    }

    function getVIPPrice() public pure returns (uint256) {
        return MINT_VIP_PRICE;
    }

    function getMintedNFTsCount() public view returns (uint256) {
        return tokenCountNormal;
    }

    function getMintedVIPNFTsCount() public view returns (uint256) {
        return tokenCountVIP;
    }

    function getTotalNFTCount() public pure returns (uint256) {
        return TOTAL_SUPPLY_CAP;
    }

    function getTotalVIPNFTCount() public pure returns (uint256) {
        return VIP_SUPPLY_CAP;
    }

    

    // Function to read the balance of an address
    function getVIPMintQuota(address user) public view returns (uint256) {
        return _VIPMintQuota[user];
    }

    // Function to increment the balance of an address
    function incrementVIPMintQuota(address user, uint256 amount) public onlyOwner {
         require(tokenId + amount <= VIP_SUPPLY_CAP, "Exceeds total VIP supply cap");
        _VIPMintQuota[user] += amount;
    }

    // Override for royalty info to always return the owner as the receiver
    function royaltyInfo(uint256 /*tokenId*/, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = owner(); // Royalties always go to the owner
        royaltyAmount = salePrice * 5 / 100; // Assuming a flat 5% royalty
        return (receiver, royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://media.istockphoto.com/id/1486357598/photo/coastal-brown-bear-fishing-in-katmai.jpg?s=1024x1024&w=is&k=20&c=CDXisI1NFpmH4oD-TmWVgGCfDUUuoS9jRu_kzzPCe0g=";
    }
}
