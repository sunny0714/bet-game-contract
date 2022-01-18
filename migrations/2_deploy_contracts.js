// const BigNumber = require('bignumber.js');
const GameToken = "0xCCf84A8B29F706F01816071f386079E9B5aBac76";

const BetGame = artifacts.require("BetGame");

module.exports = async function (deployer) {
  await deployer.deploy(BetGame, GameToken);
};
