// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BetGame is Ownable {
    using SafeMath for uint256;

    IERC20 public betGameToken;
    uint256 public rewardMultiplier;
    enum GameState {Opening, Waiting, Running}

    constructor(address _tokenAddress) {
        betGameToken = IERC20(_tokenAddress);
        rewardMultiplier = 90;
    }

    struct GamePool {
        uint256 id;
        GameState state;
        uint256 tokenAmount; // must e18, important when init
        address[] players;
    }

    GamePool[] pools;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // get number of games
    function poolLength() external view returns (uint256) {
        return pools.length;
    }

    // add pool
    function addPool(
        uint256 _tokenAmount
    ) public onlyOwner {
        pools.push(
            GamePool({
                id : pools.length.add(1),
                state: GameState.Opening,
                tokenAmount : _tokenAmount,
                players: new address[](0)
            })
        );
    }

    // update pool
    function updatePool(
        uint256 _pid,
        uint256 _tokenAmount
    ) public onlyOwner {
        uint256 poolIndex = _pid.sub(1);
        if(_tokenAmount > 0) {
            pools[poolIndex].tokenAmount = _tokenAmount;
        }
    }

    // enter into game
    function enterIntoGame(uint256 _pid) public {
        uint256 poolIndex = _pid.sub(1);
        // check balance
        require(betGameToken.balanceOf(msg.sender) >= pools[poolIndex].tokenAmount, "insufficient funds");
        // check game status
        require(pools[poolIndex].state != GameState.Running, "game is running");
        // add user
        address[] storage players = pools[poolIndex].players;
        if(pools[poolIndex].state == GameState.Opening) {
            players.push(msg.sender);
            pools[poolIndex].state = GameState.Waiting;
        } else if(pools[poolIndex].state == GameState.Waiting) {
            players.push(msg.sender);
            pools[poolIndex].state = GameState.Running;
        }
        // deposit token
        betGameToken.transferFrom(msg.sender, address(this), pools[poolIndex].tokenAmount);
        emit Transfer(msg.sender, address(this), pools[poolIndex].tokenAmount);
    }

    // claim award
    function claimAward(uint256 _pid) public {
        uint256 poolIndex = _pid.sub(1);
        // check game status
        require(pools[poolIndex].state != GameState.Running, "battle is not finished yet");
        require(pools[poolIndex].players[0] == msg.sender || pools[poolIndex].players[1] == msg.sender, "player not found");
        // initialize game
        pools[poolIndex].state = GameState.Opening;
        pools[poolIndex].players = new address[](0);
        // send award
        uint256 award = pools[poolIndex].tokenAmount.mul(2).mul(rewardMultiplier).div(100);
        betGameToken.transferFrom(address(this), msg.sender, award);
    }

    // withdraw funds
    function withdrawFund() public onlyOwner {
        uint256 balance = betGameToken.balanceOf(address(this));
        require(balance > 0, "not enough fund");
        betGameToken.transfer(msg.sender, balance);
    }
}