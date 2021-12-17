//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Types {
  uint256 public UINT256_TYPE;
  bytes32 public BYTES32_TYPE;
  bool public BOOL_TYPE;
  int256 public INT256_TYPE;
}

contract ForkableStorage {

  Forkable public parent;

  mapping( bytes32 => Stored ) internal storageHub;

  struct Stored {
    bool tf;
    bytes data;
  }

}

contract ForkableSetters is ForkableStorage {

  function set(bytes memory abiEncodedKeys, uint256 _value) internal {
    bytes32 key = keccak256(abiEncodedKeys);
    bytes memory value = abi.encode(_value);
    storageHub[key] = Stored({tf: true, data: value}); 
  }

}

contract ForkableGetters is ForkableStorage, Types {

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

contract Forkable is ForkableSetters, ForkableGetters {

}
