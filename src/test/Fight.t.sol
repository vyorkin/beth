// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Fight, InsufficientBetAmount, InvalidFighter, Finished} from "../Fight.sol";

contract FightTest is Test {
    using stdStorage for StdStorage;

    uint256 private constant FIGHTER_A = 100;
    uint256 private constant FIGHTER_B = 200;

    Fight fight;

    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);
    address eve = address(4);

    function setUp() public {
        fight = new Fight(1, FIGHTER_A, FIGHTER_B);
    }

    function testMinBet() public {
        hoax(alice, 1000);
        vm.expectRevert(
            abi.encodeWithSelector(InsufficientBetAmount.selector, 100)
        );
        fight.bet{value: 100}(FIGHTER_A);
    }

    function testBetOnFinishedFight() public {
        markFinished();
        hoax(alice, 50 ether);
        vm.expectRevert(Finished.selector);
        fight.bet{value: 10 ether}(FIGHTER_B);
    }

    function testBetOnInvalidFighter() public {
        hoax(alice, 50 ether);
        vm.expectRevert(abi.encodeWithSelector(InvalidFighter.selector, 500));
        fight.bet{value: 1 ether}(500);
    }

    function testFinishFinishedFight() public {
        markFinished();
        vm.expectRevert(Finished.selector);
        fight.finish(FIGHTER_A, FIGHTER_B);
    }

    function testFinishWithInvalidFighters() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidFighter.selector, 500));
        fight.finish(500, 600);
    }

    function testBet() public {
        startHoax(charlie, 100 ether);
        fight.bet{value: 20 ether}(FIGHTER_B);
        fight.bet{value: 10 ether}(FIGHTER_B);
        fight.bet{value: 20 ether}(FIGHTER_B);
        vm.stopPrank();

        hoax(bob, 100 ether);
        fight.bet{value: 50 ether}(FIGHTER_B);

        startHoax(eve, 100 ether);
        fight.bet{value: 10 ether}(FIGHTER_A);
        fight.bet{value: 20 ether}(FIGHTER_A);
        fight.bet{value: 20 ether}(FIGHTER_A);
        fight.bet{value: 10 ether}(FIGHTER_A);
        vm.stopPrank();

        startHoax(alice, 100 ether);
        fight.bet{value: 10 ether}(FIGHTER_A);
        fight.bet{value: 10 ether}(FIGHTER_A);
        vm.stopPrank();

        assertEq(fight.total(FIGHTER_A), 80 ether);
        assertEq(fight.total(FIGHTER_B), 100 ether);

        fight.finish(FIGHTER_A, FIGHTER_B);

        assertEq(bob.balance, 50 ether);
        assertEq(charlie.balance, 50 ether);

        assertEq(alice.balance, 100 ether + 25 ether);
        assertEq(eve.balance, 100 ether + 75 ether);
    }

    function markFinished() private {
        stdstore
            .target(address(fight))
            .sig(fight.finished.selector)
            .checked_write(true);
    }
}
