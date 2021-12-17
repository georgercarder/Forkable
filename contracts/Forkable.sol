//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Types {
  uint256 public UINT256_TYPE;
}

contract Forkable is Types {

  Forkable public parent;

  mapping( bytes32 => Stored ) private storageHub;

  struct Stored {
    bool tf;
    bytes data;
  }

  function set(bytes memory abiEncodedKeys, uint256 _value) internal {
    bytes32 key = keccak256(abiEncodedKeys);
    bytes memory value = abi.encode(_value);
    storageHub[key] = Stored({tf: true, data: value}); 
  }

  function get(bytes memory abiEncodedKeys) public returns(bytes memory value) {
    bytes32 key = keccak256(abiEncodedKeys);
    (, value) = _get(key);
    return value;
  }

  function get(bytes memory abiEncodedKeys, uint256 _type) public returns(uint256 value) {
    bytes32 key = keccak256(abiEncodedKeys);
    (, bytes memory _value) = _get(key);
    (value) = abi.decode(_value, (uint256));
    return value;
  }

  function _get(bytes32 key) public returns(bool ok, bytes memory value) {
    Stored storage s = storageHub[key]; 
    if (s.tf) {
      return (s.tf, s.data);
    } else if (address(parent) == address(0x0)) {
      return (false, value); // value is blank
    }
    return parent._get(key);
  }

}

contract Example is Forkable {
  function testWrite() external {
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
    wall = idx;
  }

  function testGetThenWrite() external {
    uint256 value = get(abi.encode("hello"), UINT256_TYPE);
    require(value == wall-1, "Example test fail.");

    set(abi.encode("hello"), wall); // need to set up encoding/decoding and make it read nicely
  }

  function testGet() external {
    uint256 value = get(abi.encode("hello"), UINT256_TYPE);
    require(value == wall, "Example test2 fail.");
  }
}
