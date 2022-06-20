const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LotteryGame", function(){

    it("addLottery: should give the owner ability to start the vote.", async function(){
        const LotteryGame = await ethers.getContractFactory("LotteryGame");
        const lottery = await LotteryGame.deploy();
        [owner] = await ethers.getSigners();
        await lottery.deployed();

        const txAddLottery = lottery.addLottery();
        await expect(txAddLottery).to.emit(lottery, 'LotteryIsCreated');
        const rAddLottery = await(await txAddLottery).wait();
        this.lotteryId = rAddLottery.events[0].args[0];
        expect(this.lotteryId).to.equal(0);
      });

})

describe("after lottery initialization", function() {
    let lotteryId = 0
    let fee = 1000
    let owner
    let better1
    let better2
    let lottery


      beforeEach(async function(){
        [owner, better1, better2] = await ethers.getSigners()

        const LotteryGame = await ethers.getContractFactory("LotteryGame", owner)
        lottery = await LotteryGame.deploy()
        await lottery.deployed()
    })

    it("getIsActive after lottery start", async function() {
        await lottery.addLottery()
        expect(await lottery.getIsActive(lotteryId)).to.be.true;
      });

    it("lottery: should be bet", async function() {
        await lottery.addLottery()
        const txLottery = lottery.connect(better1).bet(lotteryId,{ value: fee });
        await expect(txLottery).to.emit(lottery, "BetterHasBetted");
        const rLottery = await (await txLottery).wait();
        expect(rLottery.events[0].args[0]).to.equal(lotteryId);
        expect(rLottery.events[0].args[1]).to.equal(better1.address);
        expect(rLottery.events[0].args[2]).to.equal(fee);
      });

      it("lottery: should be finish", async function() {
        await lottery.addLottery()
        await lottery.connect(better1).bet(lotteryId,{ value: fee });
        await ethers.provider.send('evm_increaseTime', [60 * 60]);
        await ethers.provider.send('evm_mine');
        const txFinish = lottery.finishLottery(lotteryId);
        await expect(txFinish).to.emit(lottery, "LotteryHasEnded");
        const rFinish = await (await txFinish).wait();
        const prize = fee * 90 / 100;
        expect(rFinish.events[0].args[0]).to.equal(lotteryId);
        expect(rFinish.events[0].args[1]).to.equal(better1.address);
        expect(rFinish.events[0].args[2]).to.equal(prize);

        expect(await lottery.getIsActive(lotteryId)).to.be.false;
      });

      it("getTimeRemaining: should return 0", async function(){
        await ethers.provider.send('evm_increaseTime', [60 * 60]);
        await ethers.provider.send('evm_mine');
        expect(Number(await lottery.getTimeRemain(lotteryId))).to.equal(0);
      })
})