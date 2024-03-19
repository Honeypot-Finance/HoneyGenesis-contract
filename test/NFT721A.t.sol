// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {HoneyGenesis} from "../src/NFT721A.sol";

import {ERC721A} from "ERC721A/ERC721A.sol";
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
        // Example test: minting within supply limits and with correct payment
        uint256 mintAmount = 1;
        uint256 mintPrice = honeyGenesis.getCurrentPrice();

        // Send enough ETH to mint
        vm.deal(minter, mintPrice * mintAmount);

        // Assert preconditions
        assertEq(honeyGenesis.getMintedNFTsCount(), 0);

        // Execute mint function
        honeyGenesis.mint{value: mintPrice * mintAmount}(mintAmount);

        // Assert postconditions
        assertEq(honeyGenesis.getMintedNFTsCount(), mintAmount);
    }

    function testFailMintAboveMaxSupply() public {
        // This test should fail if trying to mint above the total supply cap
        uint256 mintAmount = honeyGenesis.getTotalNFTCount() + 1; // More than total supply
        honeyGenesis.mint{value: honeyGenesis.getCurrentPrice() * mintAmount}(mintAmount);
    }

    function testFailMintWithoutEnoughETH() public {
        // This test should fail if not sending enough ETH for mint
        uint256 mintAmount = 1;
        honeyGenesis.mint{value: 0}(mintAmount); // Not sending enough ETH
    }

    function testVIPMint() public {
        // Test VIP mint functionality
        address vipMinter = address(2);
        uint256 vipMintAmount = 2;
        uint256 vipMintPrice = honeyGenesis.getVIPPrice();

        vm.prank(address(this));
        honeyGenesis.incrementVIPMintQuota(vipMinter, vipMintAmount);

        uint256 vipMintQuotaBefore = honeyGenesis.getVIPMintQuota(vipMinter);
        assertEq(vipMintQuotaBefore, vipMintAmount);

        vm.deal(vipMinter, vipMintPrice * vipMintAmount);
        vm.startPrank(vipMinter);
        honeyGenesis.mintVIP{value: vipMintPrice * vipMintAmount}(vipMintAmount);
        vm.stopPrank();

        uint256 vipMintQuotaAfter = honeyGenesis.getVIPMintQuota(vipMinter);
        assertEq(vipMintQuotaAfter, 0); // Quota should be used up
        assertEq(honeyGenesis.getMintedVIPNFTsCount(), vipMintAmount);
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
        // assertTrue(honeyGenesis.supportsInterface(type(IERC721A).interfaceId), "Should support IERC721A.");
        assertTrue(honeyGenesis.supportsInterface(type(IERC2981).interfaceId), "Should support IERC2981.");
    }
}
