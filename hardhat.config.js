require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("solidity-coverage");
require("dotenv").config();

const {ALCHEMY_KEY, PRIVATE_KEY, ETHERSCAN_API_KEY} = process.env;

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 module.exports = {
  solidity: "0.8.5",
  defaultNetwork: "rinkeby",
  networks: {
    rinkeby: {
      url: ALCHEMY_KEY,
      accounts: [PRIVATE_KEY]
    },

    hardhat: {
      chainId: 1337
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY
  }
};
