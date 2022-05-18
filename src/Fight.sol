// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";

// win = bet + (bet / total_bets_on_winner * total_bets_on_loser)

// use case:
//
// total_bets_on_fighter_2 = 100 ETH
//
// eve   bet 60 ETH on fighter_1
// alice bet 20 ETH on fighter_1
//
// total_bets_on_fighter_1 = 80 ETH
//
// alice reward: 20 + (20 / 80 * 100) = 20 + 1/4 * 100 = 45 ETH
//   eve reward: 60 + (60 / 80 * 100) = 60 + 3/4 * 100 = 135 ETH
//
// alice balance: 100 - 20 + 45  = 125 ETH
//   eve balance: 100 - 60 + 135 = 175 ETH

error InsufficientBetAmount(uint256 amount);
error InvalidFigther(uint256 figher);
error Finished();
error PayoutFailed(address receiver, uint256 amount);

contract Fight is Owned {
    event NewBet(
        address indexed bettor,
        uint256 indexed fighter,
        uint256 amount
    );
    event NewPayout(address indexed bettor, uint256 amount);
    event FightFinished(uint256 winner, uint256 loser);

    uint256 public constant MIN_BET = 1000;
    uint256 public constant MAX_BETTORS = 100;

    uint256 private id;
    uint256 private fighterA;
    uint256 private fighterB;
    mapping(uint256 => address[]) private bettors;
    mapping(address => mapping(uint256 => uint256)) private bets;
    mapping(uint256 => uint256) public total;
    bool private finished;

    constructor(
        uint256 _id,
        uint256 _fighterA,
        uint256 _fighterB
    ) Owned(msg.sender) {
        id = _id;
        fighterA = _fighterA;
        fighterB = _fighterB;
    }

    modifier notFinished() {
        if (finished) {
            revert Finished();
        }
        _;
    }

    modifier validFighter(uint256 _fighter) {
        if (_fighter != fighterA && _fighter != fighterB) {
            revert InvalidFigther(_fighter);
        }
        _;
    }

    function bet(uint256 _fighter)
        external
        payable
        notFinished
        validFighter(_fighter)
    {
        if (msg.value < MIN_BET) {
            revert InsufficientBetAmount(msg.value);
        }

        if (bets[msg.sender][_fighter] == 0) {
            bettors[_fighter].push(msg.sender);
        }
        bets[msg.sender][_fighter] += msg.value;
        total[_fighter] += msg.value;

        emit NewBet(msg.sender, _fighter, msg.value);
    }

    function finish(uint256 _winner, uint256 _loser)
        external
        notFinished
        validFighter(_winner)
        validFighter(_loser)
        onlyOwner
    {
        finished = true;

        for (uint256 i = 0; i < bettors[_winner].length; i++) {
            address payable bettor = payable(bettors[_winner][i]);
            uint256 amount = bets[bettor][_winner];
            uint256 reward = (amount *
                (10000 + ((total[_loser] * 10000) / total[_winner]))) / 10000;
            (bool sent, ) = bettor.call{value: reward}("");
            if (!sent) {
                revert PayoutFailed(bettor, reward);
            }
            emit NewPayout(bettor, reward);
        }

        emit FightFinished(_winner, _loser);
    }
}
