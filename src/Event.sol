// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {Fight} from "./Fight.sol";

contract Event is Owned {
    event FightCreated(address indexed fight);

    uint256 private id;

    constructor(uint256 _id) Owned(msg.sender) {
        require(_id > 0, "Invalid event id");
        id = _id;
    }

    function createFight(uint256 _fighterA, uint256 _fighterB) public {
        new Fight(id, _fighterA, _fighterB);
    }
}

// Ideas:
//
// - Accumulated strike/combo-rewards for win-series
// - Bet-staking:
//   + Contract uses placed bets
//   + Bettors earn rewards for their bets
