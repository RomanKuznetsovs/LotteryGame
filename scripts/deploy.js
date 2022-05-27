const hre = require("hardhat");
const ethers = hre.ethers

async function main() {
  const[signer] = await ethers.getSigners()

  const LotteryGame = await ethers.getContractFactory("LotteryGame");
  const lottery = await LotteryGame.deploy();
  await lottery.deployed();

  console.log(lottery.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
