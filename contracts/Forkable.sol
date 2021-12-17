//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Forkable {

  Forkable public parent;

  mapping( bytes32 => Stored ) private storageHub;

  struct Stored {
    bool tf;
    uint256 data;
  }

  function set(bytes32 key, uint256 value) internal {
    storageHub[key] = Stored({tf: true, data: value}); 
  }

  function get(bytes32 key) public returns(bool ok, uint256 value) {
    Stored storage s = storageHub[key]; 
    if (s.tf) {
      return (s.tf, s.data);
    } else if (address(parent) == address(0x0)) {
      return (false, value); // value is blank
    }
    return parent.get(key);
  }

}

contract Example is Forkable {
  function testWrite() external {
    set(keccak256(abi.encode("hello")), 1); // need to set up encoding/decoding and make it read nicely
  }

  function testGet() external {
    (bool ok, uint256 value) = get(keccak256(abi.encode("hello")));
    require(value == 1, "Example test2 fail.");
  }
}

contract ExampleForked is Forkable {
  uint256 private wall;
  constructor(address _parent, uint256 idx) {
    parent = Forkable(_parent); 
    wall = idx;
  }

  function testGetThenWrite() external {
    (bool ok, uint256 value) = get(keccak256(abi.encode("hello")));
    require(value == wall-1, "Example test fail.");

    set(keccak256(abi.encode("hello")), wall); // need to set up encoding/decoding and make it read nicely
  }

  function testGet() external {
    (bool ok, uint256 value) = get(keccak256(abi.encode("hello")));
    require(value == wall, "Example test2 fail.");
  }
}
