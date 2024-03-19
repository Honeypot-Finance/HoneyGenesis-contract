// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "ERC721A/ERC721A.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

contract HoneyGenesis is ERC721A, IERC2981, Ownable {
    event NFTMinted(address indexed minter, uint256 amount, uint256 value);
    event FundWithdrawn(address owner, uint256 amount);

    uint256 private constant TOTAL_SUPPLY_CAP = 5000; // max 5000 NFTs normal minting
    uint256 private constant VIP_SUPPLY_CAP = 1000; // max 1000 NFTs for VIP minting

    uint256 private constant MINT_VIP_PRICE = 0.069 ether; // 0.069 ETH minting fee for VIP
    uint256 private constant MINT_UNIT_PRICE = 0.07 ether; // 0.07 ETH minting fee for normal wallets
    uint256 private constant PRICE_INCREMENT = 0.007 ether; // 0.007 ETH price increment

    uint256 private constant SUPPLY_INCREMENT_STEPSIZE = 500; // After the first 1000 NFTs, the price will increase every 500 NFTs
    uint256 private constant MAX_MINT_AMOUNT = 20; // Max 20 NFTs for each normal wallets

    uint256 public tokenCountNormal; // normal minted NFTs
    uint256 public tokenCountVIP; // vip minted NFTs

    mapping(address => uint256) private _VIPMintQuota; // whitelisted wallets can only mint up to a quota at VIP price

    error Overflow();
    error InsufficientEther(uint256 required, uint256 provided);
    error ExceedsMaxSupply(uint256 requested, uint256 available);
    error ExceedsVIPMaxSupply(uint256 requested, uint256 available);

    constructor() ERC721A("HoneyGenesis", "HONEY") Ownable(msg.sender) {
        tokenCountNormal = 0;
        tokenCountVIP = 0;
    }

    function mint(uint256 amount) public payable {
        address minter = msg.sender;
        uint256 totalCost = amount * _calcPrice(tokenCountNormal);

        if (msg.value < totalCost) {
            revert InsufficientEther({
                required: totalCost,
                provided: msg.value
            });
        }

        if (tokenCountNormal + amount > TOTAL_SUPPLY_CAP) {
            revert ExceedsMaxSupply({
                requested: amount,
                available: TOTAL_SUPPLY_CAP - tokenCountNormal
            });
        }

        require(amount <= MAX_MINT_AMOUNT, "Exceeds max mint amount");

        _safeMint(msg.sender, amount); // gas efficient, you can use batchMint function from ERC721A
        tokenCountNormal += amount;

        emit NFTMinted(minter, amount, msg.value);
        //Added a refund mechanism in case the user sends too much eth
        uint256 excess = msg.value - totalCost;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
    }

    function mintbyKingdomly(uint256 amount) public payable {
        uint256 currentPrice = _calcPrice(tokenCountNormal);
        uint256 totalCost = currentPrice * amount;

        uint256 kingdomlyFee = ((totalCost * 3) / 100) +
            (1000000000000000 * amount); //$3 in wei + 3% fee

        uint256 totalCostWithFee = totalCost + kingdomlyFee;

        if (msg.value < totalCostWithFee) {
            revert InsufficientEther({
                required: totalCostWithFee,
                provided: msg.value
            });
        }

        if (tokenCountNormal + amount > TOTAL_SUPPLY_CAP) {
            revert ExceedsMaxSupply({
                requested: amount,
                available: TOTAL_SUPPLY_CAP - tokenCountNormal
            });
        }

        require(amount <= MAX_MINT_AMOUNT, "Exceeds max mint amount"); // <--- this is abusable, people can just hit mint as many times they want, I suggest using ERC721A _numberMinted soon.

        _safeMint(msg.sender, amount); // gas efficient, you can use batchMint function from ERC721A
        tokenCountNormal += amount;

        emit NFTMinted(msg.sender, amount, msg.value);

        //Added a refund mechanism in case the user sends too much eth
        uint256 excess = msg.value - totalCostWithFee;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
    }

    function mintVIP(uint256 amount) public payable {
        address minter = msg.sender;
        uint256 totalCost = amount * MINT_VIP_PRICE;

        if (msg.value < totalCost) {
            revert InsufficientEther({
                required: totalCost,
                provided: msg.value
            });
        }

        if (tokenCountVIP + amount > VIP_SUPPLY_CAP) {
            revert ExceedsVIPMaxSupply({
                requested: amount,
                available: VIP_SUPPLY_CAP - tokenCountVIP
            });
        }

        require(_VIPMintQuota[minter] >= amount, "Exceeds VIP mint quota");

        _VIPMintQuota[minter] -= amount;

        _safeMint(msg.sender, amount); // gas efficient, you can use batchMint function from ERC721A
        tokenCountVIP += amount;

        emit NFTMinted(minter, amount, msg.value);
        //Added a refund mechanism in case the user sends too much eth
        uint256 excess = msg.value - totalCost;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        // Updating the state before the transfer for prevention of reentrancy attacks
        emit FundWithdrawn(owner(), balance);

        // Interaction
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function getCurrentPrice() public view returns (uint256) {
        return _calcPrice(tokenCountNormal);
    }

    function getNextNFTPrice() public view returns (uint256) {
        uint256 nexttokenId = tokenCountNormal + SUPPLY_INCREMENT_STEPSIZE;
        if (nexttokenId > TOTAL_SUPPLY_CAP) {
            revert Overflow();
        }
        return _calcPrice(nexttokenId);
    }

    function _calcPrice(uint256 priceParam) private pure returns (uint256) {
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
    function incrementVIPMintQuota(
        address user,
        uint256 amount
    ) public onlyOwner {
        require(
            tokenCountVIP + amount <= VIP_SUPPLY_CAP,
            "Exceeds total VIP supply cap"
        );
        _VIPMintQuota[user] += amount;
    }

    // Override for royalty info to always return the owner as the receiver
    function royaltyInfo(
        uint256 /*tokenId*/,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = owner(); // Royalties always go to the owner
        royaltyAmount = (salePrice * 5) / 100; // Assuming a flat 5% royalty
        return (receiver, royaltyAmount);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal pure override returns (string memory) {
        return
            "https://bafkreifj2vyb3s77yrafreyoupk4ghjoyqsxiqoot2wjzev5tfstpjeqlm.ipfs.nftstorage.link";
    }
}
