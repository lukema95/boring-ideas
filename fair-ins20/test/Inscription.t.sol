// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {INS20} from "../src/Inscription.sol";
import {Strings} from "../src/Strings.sol";

contract InscriptionTest is Test {
    INS20 public inscription;
    address alice = vm.addr(1);
    address bob = vm.addr(2);
    address cat = vm.addr(3);
    address dog = vm.addr(4);

    function setUp() public {
        inscription = new INS20(
          "fair-ins20",
          21000000,
          1000,
          1000,
          alice,
          21000000,
          10,
          1000,
          100000
        );
    }

    function test_MintingAlgo() public {
        bool isSucceeded = inscription.mintingAlgo(21000000, 10);
        console2.log("isSucceeded", isSucceeded);
    }

    function test_MintingAlgoRate() public {
      uint64 cnt = 0;
      uint256 loop = 10000;
      uint256 total = loop;
      while (loop > 0) {
        bool isSucceeded = inscription.mintingAlgo(21001099, 10);
        if (isSucceeded) {
          cnt++;
        }
        loop--;
      }

      console2.log("succeeded", cnt);
      console2.log("succeeded rate", cnt * 100 / total);
    }

    function test_Inscribe() public {
      vm.startPrank(alice, alice);
      inscription.inscribe(10);
      inscription.inscribe(10);
      inscription.inscribe(10);
      console2.log("mintedPer", inscription.mintedPer());
    }

    function test_RevertWhen_InscribeByContract() public {
      vm.expectRevert("Contracts are not allowed");
      vm.startPrank(alice);
      inscription.inscribe(10);
    }

    function test_RevertWhen_InscribeOverTxLimit() public {
      vm.expectRevert("Exceeded per tx limit");
      vm.startPrank(alice, alice);
      inscription.inscribe(1001);
    }

    function test_RevertWhen_InscribeOverWalletLimit() public {
      vm.skip(true);
      vm.startPrank(alice, alice);
      vm.expectRevert("Exceeded per wallet limit");
      for (uint256 i = 0; i < 101; i++) {
        inscription.inscribe(10);
      }
      console2.log("wallet balance", inscription.balanceOf(alice));
    }

    function test_RevertWhen_InscribeOverMaxSupply() public {
      vm.skip(true);
      vm.startPrank(alice, alice);
      // stdstore
      // .target(address(inscription))
      // .sig(inscription._totalSupply.selector)
      // .checked_write(21000000);
      vm.expectRevert("Exceeded max supply");
      inscription.inscribe(11);
      console2.log("total supply", inscription.totalSupply());
    }

    function test_VoteForFT() public {
      vm.startPrank(alice, alice);
      inscription.inscribe(10);
      inscription.inscribe(10);
      uint256[] memory params = new uint256[](2);
      params[0] = 0;
      params[1] = 1;
      inscription.voteForFT(params);
      assertEq(inscription.totalVotedAmount(), 20);
    }

    function test_RevertWhen_VoteByNotOwner() public {
      vm.startPrank(alice, alice);
      inscription.inscribe(1);
      uint256[] memory params = new uint256[](1);
      params[0] = 0;
      vm.startPrank(bob, bob);
      vm.expectRevert("Not owner");
      inscription.voteForFT(params);
    }

    function test_TokenURI() public {
      vm.startPrank(alice, alice);
      inscription.inscribe(1);
      string memory uri = inscription.tokenURI(0);
      console2.log("uri", uri); 
    }

    function test_Approve721() public {
      vm.startPrank(alice, alice);
      inscription.inscribe(1);
      inscription.approve(bob, 0);
      console2.log("approved", inscription.getApproved(0));
      assert(inscription.getApproved(0) == bob);

      vm.startPrank(bob);
      inscription.transferFrom(alice, cat, 0);
      assert(inscription.ownerOf(0) == cat);
    }

    function test_Approve20() public {
      vm.startPrank(alice, alice);
      inscription.inscribe(10);

      inscription.toFT();

      inscription.approve(bob, 1);

      vm.startPrank(bob);
      inscription.transferFrom(alice, cat, 1);
    }

    function test_setApproveForAll() public {
      vm.startPrank(alice, alice);
      inscription.inscribe(1);
      inscription.inscribe(1);
      inscription.setApprovalForAll(bob, true);
      assert(inscription.isApprovedForAll(alice, bob));

      vm.startPrank(bob);
      inscription.transferFrom(alice, cat, 0);
      inscription.transferFrom(alice, cat, 1);
      assert(inscription.ownerOf(0) == cat);
    }
}