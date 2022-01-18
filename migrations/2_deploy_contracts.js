// const BigNumber = require('bignumber.js');

const BetGame = artifacts.require("BetGame");

module.exports = async function (deployer) {
  await deployer.deploy(BetGame);
};
