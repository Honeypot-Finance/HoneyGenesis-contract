// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {HoneyGenesis1} from "../src/NFT.sol";

import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract HoneyGenesis1Test is Test {
    HoneyGenesis1 honeyGenesis;
    address owner;
    address minter;

    function setUp() public {
        owner = address(this);
        minter = address(0x1);
        honeyGenesis = new HoneyGenesis1(); // Use a dummy merkleRoot for simplicity
    }

    function testDeployment() public {
        assertEq(
            honeyGenesis.owner(),
            owner,
            "Owner should be set correctly on deployment."
        );
    }

    function testMintWithoutEnoughEth() public {
        uint256 mintAmount = 2;
        vm.prank(minter);
        vm.expectRevert("Ether sent is not correct");
        honeyGenesis.mint(1, mintAmount);
    }

    function testMint() public {
        uint256 mintAmount = 2;
        uint256 mintPrice = honeyGenesis.getCurrentPrice() * mintAmount;
        vm.deal(minter, mintPrice);
        vm.prank(minter);
        honeyGenesis.mint{value: mintPrice}(1, mintAmount);

        assertEq(
            honeyGenesis.balanceOf(minter, 1),
            mintAmount,
            "Minter should have the correct amount of NFTs."
        );

        assertEq(
            honeyGenesis.totalSupply(),
            mintAmount,
            "TotalSupply should update correctly."
        );
    }

    function testMintExceedsSupply() public {
        vm.prank(minter);
        uint256 mintAmount = 6001; // TOTAL_SUPPLY_CAP is 6000
        uint256 mintPrice = honeyGenesis.getCurrentPrice() * mintAmount;
        vm.deal(minter, mintPrice);

        vm.expectRevert("Exceeds total supply cap");
        honeyGenesis.mint{value: mintPrice}(1, mintAmount);
    }

    function testWithdraw() public {
        // First, mint some NFTs to provide the contract with balance
        uint256 mintAmount = 2;
        uint256 mintPrice = honeyGenesis.getCurrentPrice() * mintAmount;
        vm.deal(minter, mintPrice);
        vm.prank(minter);
        honeyGenesis.mint{value: mintPrice}(1, mintAmount);

        // Attempt to withdraw as non-owner should fail
        vm.prank(minter);
        vm.expectRevert();
        honeyGenesis.withdraw();

        // Withdraw as owner should succeed
        uint256 contractBalanceBefore = address(honeyGenesis).balance;
        uint256 ownerBefore = owner.balance;
        vm.prank(owner);
        honeyGenesis.withdraw();
        uint256 ownerBalanceAfter = owner.balance;

        assertEq(
            ownerBalanceAfter - ownerBefore,
            contractBalanceBefore,
            "Owner should receive the contract balance."
        );
    }

    function testRoyaltyInfo() public {
        uint256 salePrice = 1 ether;
        (address receiver, uint256 royaltyAmount) = honeyGenesis.royaltyInfo(
            1,
            salePrice
        );

        assertEq(receiver, owner, "Royalty receiver should be the owner.");
        assertEq(
            royaltyAmount,
            (salePrice * 3) / 100,
            "Royalty amount should be correct."
        );
    }

    function testSupportsInterface() public {
        assertTrue(
            honeyGenesis.supportsInterface(type(IERC1155).interfaceId),
            "Should support IERC1155."
        );
        assertTrue(
            honeyGenesis.supportsInterface(type(IERC2981).interfaceId),
            "Should support IERC2981."
        );
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
