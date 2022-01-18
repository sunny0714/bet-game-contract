const PolkaWarToken = artifacts.require("PolkaWarToken");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("PolkaWarToken", function (/* accounts */) {
  it("should assert true", async function () {
    await PolkaWarToken.deployed();
    return assert.isTrue(true);
  });
});
