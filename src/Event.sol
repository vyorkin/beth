// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";

contract Event is Owned {
    event FightCreated(address indexed fight);

    constructor() Owned(msg.sender) {}
}

// Ideas:
//
// - Accumulated strike/combo-rewards for win-series
// - Bet-staking:
//   + Contract uses placed bets
//   + Bettors earn rewards for their bets
