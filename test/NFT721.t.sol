// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {HoneyGenesis} from "../src/NFT721.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract HoneyGenesisTest is Test {
HoneyGenesis honeyGenesis;
    address owner;
    address minter;

    function setUp() public {
        owner = address(this);
        minter = address(0x1);
        honeyGenesis = new HoneyGenesis(); // Use a dummy merkleRoot for simplicity
        honeyGenesis.transferOwnership(owner);
    }

    function testDeployment() public {
        assertEq(honeyGenesis.owner(), owner, "Owner should be set correctly on deployment.");
    }

    function testMint() public {
        vm.prank(minter);
        uint256 mintAmount = 2;
        uint256 mintPrice = honeyGenesis.getCurrentPrice() * mintAmount;
        vm.deal(minter, mintPrice);
        honeyGenesis.mint{value: mintPrice}(mintAmount);

        assertEq(honeyGenesis.balanceOf(minter), mintAmount, "Minter should have the correct amount of NFTs.");
        assertEq(honeyGenesis.tokenId(), mintAmount, "Token ID should increment correctly.");
    }

    function testMintExceedsMaxAmount() public {
        vm.prank(minter);
        uint256 mintAmount = 21; // MAX_MINT_AMOUNT is 20
        uint256 mintPrice = honeyGenesis.getCurrentPrice() * mintAmount;
        vm.deal(minter, mintPrice);

        vm.expectRevert("Exceeds max mint amount");
        honeyGenesis.mint{value: mintPrice}(mintAmount);
    }

    function testWithdraw() public {
        // First, mint some NFTs to provide the contract with balance
        vm.prank(minter);
        uint256 mintAmount = 2;
        uint256 mintPrice = honeyGenesis.getCurrentPrice() * mintAmount;
        vm.deal(minter, mintPrice);
        honeyGenesis.mint{value: mintPrice}(mintAmount);

        // Attempt to withdraw as non-owner should fail
        vm.prank(minter);
        vm.expectRevert("Ownable: caller is not the owner");
        honeyGenesis.withdraw();

        // Withdraw as owner should succeed
        uint256 contractBalanceBefore = address(honeyGenesis).balance;
        vm.prank(owner);
        honeyGenesis.withdraw();
        uint256 ownerBalanceAfter = owner.balance;

        assertEq(ownerBalanceAfter, contractBalanceBefore, "Owner should receive the contract balance.");
    }

    function testRoyaltyInfo() public {
        uint256 salePrice = 1 ether;
        (address receiver, uint256 royaltyAmount) = honeyGenesis.royaltyInfo(1, salePrice);

        assertEq(receiver, owner, "Royalty receiver should be the owner.");
        assertEq(royaltyAmount, salePrice * 5 / 100, "Royalty amount should be correct.");
    }

    function testSupportsInterface() public {
        assertTrue(honeyGenesis.supportsInterface(type(IERC721).interfaceId), "Should support IERC721.");
        assertTrue(honeyGenesis.supportsInterface(type(IERC2981).interfaceId), "Should support IERC2981.");
    }
}
