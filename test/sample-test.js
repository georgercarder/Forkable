const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Example = await ethers.getContractFactory("Example");
    const example = await Example.deploy();
    await example.deployed();

    await example.testWrite();
    await example.testGet();

    const ExampleForked = await ethers.getContractFactory("ExampleForked");
    const exampleForked = await ExampleForked.deploy(example.address, 2);
    await exampleForked.deployed();

    await exampleForked.testGetThenWrite();
    await exampleForked.testGet();

    // this is forked from exampleForked
    const exampleForked2 = await ExampleForked.deploy(exampleForked.address, 3);
    await exampleForked2.deployed();

    await exampleForked2.testGetThenWrite();
    await exampleForked2.testGet();

    // note this also is forked from exampleForked
    const exampleForked3 = await ExampleForked.deploy(exampleForked.address, 3);
    await exampleForked3.deployed();

    await exampleForked3.testGetThenWrite();
    await exampleForked3.testGet();

  });
});
