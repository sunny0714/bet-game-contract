// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ReentrancyGuard.sol";

contract BetGame is Ownable, ReentrancyGuard {

    IERC20 public betGameToken;
    uint256 public rewardMultiplier;
    enum GameState {Opening, Waiting, Running} //, Finished}

    constructor(address _tokenAddress) {
        betGameToken = IERC20(_tokenAddress);
        rewardMultiplier = 90;
    }

    struct GamePool {
        uint256 id;
        GameState state;
        uint256 tokenAmount; // token amount needed to enter each pool. must e18, important when init
        address[] players;
    }

    GamePool[] public pools;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event LogClaimAward(uint256 indexed pid, address indexed winnerAddress, uint256 award);

    // get number of games
    function poolLength() external view returns (uint256) {
        return pools.length;
    }

    // add pool
    function addPool(
        uint256 _tokenAmount
    ) external onlyOwner {
        pools.push(
            GamePool({
                id : pools.length + 1,
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
    ) external onlyOwner {
        uint256 poolIndex = _pid - 1;
        if(_tokenAmount > 0) {
            pools[poolIndex].tokenAmount = _tokenAmount;
        }
    }

    // bet game
    function bet(uint256 _pid) external {
        uint256 poolIndex = _pid - 1;
        // check balance
        require(betGameToken.balanceOf(msg.sender) >= pools[poolIndex].tokenAmount, "insufficient funds");
        // check game status
        require(pools[poolIndex].state != GameState.Running, "game is running");
        // add user
        if(pools[poolIndex].state == GameState.Opening) {
            pools[poolIndex].players.push(msg.sender);
            pools[poolIndex].state = GameState.Waiting;
        } else if(pools[poolIndex].state == GameState.Waiting) {
            pools[poolIndex].players.push(msg.sender);
            pools[poolIndex].state = GameState.Running;
        }
        // deposit token
        betGameToken.transferFrom(msg.sender, address(this), pools[poolIndex].tokenAmount / 1e18);
        emit Transfer(msg.sender, address(this), pools[poolIndex].tokenAmount / 1e18);
    }

    // update game status
    // function updateStatus(uint256 _pid) external onlyOwner {
    //     uint256 poolIndex = _pid - 1;
    //     require(pools[poolIndex].state == GameState.Running, 'No time to finish the game');
    //     pools[poolIndex].state = GameState.Finished;
    // }

    // claim award
    function claimAward(uint256 _pid, address _winnerAddress) external onlyOwner nonReentrant {
        uint256 poolIndex = _pid - 1;
        // check game status
        require(pools[poolIndex].state == GameState.Running, "no valid time");
        require(pools[poolIndex].players[0] == _winnerAddress || pools[poolIndex].players[1] == _winnerAddress, "player not found");
        // send award
        uint256 award = pools[poolIndex].tokenAmount / 1e18 * 2 * rewardMultiplier / 100;
        uint256 gasFee = pools[poolIndex].tokenAmount / 1e18 * 2 * (100 - rewardMultiplier) / 100;
        betGameToken.transferFrom(address(this), _winnerAddress, award);
        betGameToken.transferFrom(address(this), msg.sender, gasFee);
        emit LogClaimAward(_pid, _winnerAddress, award);
        // initialize game
        pools[poolIndex].state = GameState.Opening;
        pools[poolIndex].players = new address[](0);
    }

    // withdraw funds
    function withdrawFund() external onlyOwner {
        uint256 balance = betGameToken.balanceOf(address(this));
        require(balance > 0, "not enough fund");
        betGameToken.transfer(msg.sender, balance);
    }
}