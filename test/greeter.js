const { ethers } = require("hardhat");

const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");




  describe("Greeter", function (){
    it("return the new greeting once it is change", async function(){
        const Greeter = await ethers.getContractFactory("Greeter");
        const greeter = await Greeter.deploy("Hello World!");
        await greeter.deployed();

        const currentGreet = await greeter.getGreet();
        console.log("current greeter", currentGreet);
        
        expect(await greeter.getGreet()).to.equal("Hello World!");

        const setGreetingTx = await greeter.setGreet("Happy new month");


        //wait until the transaction is mind

        await setGreetingTx.wait();

        expect(await greeter.getGreet()).to.equal("Happy new month");


    })

    it("return deposit value", async function(){
        const Greeter = await ethers.getContractFactory("Greeter");
        const greeter = await Greeter.deploy("Hello World!");
        await greeter.deployed();

       await greeter.deposit({value: 10});

       expect(await ethers.provider.getBalance(greeter.address)).to.equal(10);


    })

  });


