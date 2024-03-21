// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/HoneyGenesis.sol";

contract HoneyGenesisTest is Test {
    HoneyGenesis honeyGenesis;
    address owner;
    address addr1;
    address addr2;

    function setUp() public {
        owner = address(this); // Test contract is the owner
        honeyGenesis = new HoneyGenesis();
        addr1 = address(0x1);
        addr2 = address(0x2);
    }

    function testDeployment() public {
        assertEq(honeyGenesis.owner(), owner, "Owner should be set correctly on deployment.");
    }

    function getOwner() public view returns (address) {
        return honeyGenesis.owner();
    }

    function getMintPrice(uint256 amount) public view returns (uint256) {
        return (honeyGenesis.getCurrentPrice() * 103 / 100 + 900000000000000) * amount;
    }

    function testMint() public {
        // Example test for normal minting
        uint256 amount = 1;
        uint256 mintPrice = (honeyGenesis.getCurrentPrice() * 103 / 100 + 900000000000000) * amount;

        // Simulate sending ETH with the mint function call
        vm.deal(addr1, mintPrice);
        vm.startPrank(addr1);

        honeyGenesis.mint{value: mintPrice}(amount);

        // Asserts to verify the mint was successful
        assertEq(honeyGenesis.balanceOf(addr1), amount);

        vm.stopPrank();
    }

    function testMintVIP() public {
        // Setup VIP quota for addr1
        uint256 amount = 2;
        address[] memory addresses = new address[](2);
        addresses[0] = addr1;
        addresses[1] = addr2;

        uint256[] memory amounts = new uint256[](2); // Dynamic array of size 2
        amounts[0] = amount;
        amounts[1] = 2;

        honeyGenesis.incrementVIPMintQuota(addresses, amounts);

        uint256 vipMintPrice = (honeyGenesis.getVIPPrice() + 900000000000000) * amount;

        // Ensure addr1 has enough ETH
        vm.deal(addr1, vipMintPrice);
        vm.startPrank(addr1);

        honeyGenesis.mintVIP{value: vipMintPrice}(amount);

        // Verify the mint was successful and the quota decreased
        assertEq(honeyGenesis.balanceOf(addr1), amount);
        assertEq(honeyGenesis.getVIPMintQuota(addr1), 0);

        vm.stopPrank();
    }

    function testWithdraw() public {
        // Mint an NFT to generate funds in the contract
        uint256 mintAmount = 1;
        uint256 mintPrice = getMintPrice(mintAmount);
        honeyGenesis.mint{value: mintPrice}(mintAmount);

        // Capture the initial balances
        uint256 initialBalanceOwner = owner.balance;

        // Withdraw funds as the owner
        vm.prank(owner);
        honeyGenesis.withdraw();

        // Assert that the owner's balance has increased by the expected amount
        assertGt(owner.balance, initialBalanceOwner);
    }

    function testAccessControl() public {
        // Attempt to call an owner-only function from a non-owner address
        vm.startPrank(addr1);
        vm.expectRevert("Ownable: caller is not the owner");
        honeyGenesis.setBaseURI("https://newbaseuri.com/");
        vm.stopPrank();
    }
}
