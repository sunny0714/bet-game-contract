// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BetGame {

    IERC20 public BetGameToken;
    address public owner;
    uint256 public rewardMultiplier;
    uint[] _entry = [10, 50, 100, 200, 500, 1000];
    enum GameState {Open, Waiting, Running}

    struct Game {
        uint id;
        GameState state;
        address[] players;
    }

    mapping(uint256 => Game) public gamelist;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    constructor(address _TokenAddress) {
        BetGameToken = IERC20(_TokenAddress);
        owner = msg.sender;
        rewardMultiplier = 90;
        startAllGames();
    }

    function startAllGames() internal {
        for (uint256 i = 0; i < _entry.length; i++) {
            gamelist[i] = Game(i, GameState.Open, new address[](0));
        }
    }
}