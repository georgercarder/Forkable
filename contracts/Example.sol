//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Forkable.sol";

contract Example is Forkable {

  constructor() {}

  function testWrite() external {
    // try get before exists
    uint256 value = get(abi.encode("hello"), UINT256_TYPE);
    require(value == 0, "should be 0");
    //
    set(abi.encode("hello"), 1); // need to set up encoding/decoding and make it read nicely
  }

  function testGet() external {
    uint256 value = get(abi.encode("hello"), UINT256_TYPE);
    require(value == 1, "Example test2 fail.");
  }
}

contract ExampleForked is Forkable {
  
  uint256 private wall;
  constructor(address _parent, uint256 idx) {
    parent = Forkable(_parent); 
    parent.fork();
    wall = idx;
  }

  function testGetThenWrite() external {
    uint256 value = get(abi.encode("hello"), UINT256_TYPE);
    require(value == wall-1, "Example test fail.");

    update(abi.encode("hello"), wall); // need to set up encoding/decoding and make it read nicely
  }

  function testGet() external {
    uint256 value = get(abi.encode("hello"), UINT256_TYPE);
    require(value == wall, "Example test2 fail.");
  }
}
