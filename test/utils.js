const { BigNumber } = require("ethers");

module.exports = {
  toNum: (bigNumber) => {
    return Number(bigNumber.toString());
  },
  toBN: (number) => {
    return BigNumber.from(number);
  },
  sleep: async (delay = 5) => {
    await new Promise((resolve) => {
      setTimeout(resolve, delay * 1000);
    });
  },
};
