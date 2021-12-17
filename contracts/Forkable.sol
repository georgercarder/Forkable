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

contract Forkable is ForkableStorage, Types {

  // SETTERS
  // note: setting can only happen once, see updaters

  function set(bytes memory abiEncodedKeys, bytes memory value) internal {
    _set(keccak256(abiEncodedKeys), value);
  }

  function set(bytes memory abiEncodedKeys, uint256 value) internal {
    _set(keccak256(abiEncodedKeys), abi.encode(value));
  }

  function set(bytes memory abiEncodedKeys, bytes32 value) internal {
    _set(keccak256(abiEncodedKeys), abi.encode(value));
  }

  function set(bytes memory abiEncodedKeys, bool value) internal {
    _set(keccak256(abiEncodedKeys), abi.encode(value));
  }

  function _set(bytes32 key, bytes memory value) private {
    if (!storageHub[key].tf) { // if never set
      storageHub[key] = Stored({tf: true, data: value}); 
    }
  }

  /* // need to figure out how this would be disambiguated from uint256...
  function set(bytes memory abiEncodedKeys, int256 value) internal {
    storageHub[keccak256(abiEncodedKeys)] = Stored({tf: true, data: abi.encode(value)}); 
  }*/


  // UPDATERS

  function update(bytes memory abiEncodedKeys, bytes memory value) internal {
    _update(keccak256(abiEncodedKeys), value);
  }

  function update(bytes memory abiEncodedKeys, uint256 value) internal {
    _update(keccak256(abiEncodedKeys), abi.encode(value));
  }

  function update(bytes memory abiEncodedKeys, bytes32 value) internal {
    _update(keccak256(abiEncodedKeys), abi.encode(value));
  }

  function update(bytes memory abiEncodedKeys, bool value) internal {
    _update(keccak256(abiEncodedKeys), abi.encode(value));
  }

  function _update(bytes32 key, bytes memory value) private {
    storageHub[key] = Stored({tf: true, data: value}); 
  }

  // GETTERS

  function get(bytes memory abiEncodedKeys) public returns(bytes memory value) {
    (, value) = _get(keccak256(abiEncodedKeys));
    return value;
  }

  function get(bytes memory abiEncodedKeys, uint256 _type) public returns(uint256 value) {
    (, bytes memory _value) = _get(keccak256(abiEncodedKeys));
    return abi.decode(_value, (uint256));
  }

  function get(bytes memory abiEncodedKeys, bytes32 _type) public returns(bytes32 value) {
    (, bytes memory _value) = _get(keccak256(abiEncodedKeys));
    return abi.decode(_value, (bytes32));
  }

  function get(bytes memory abiEncodedKeys, bool _type) public returns(bool value) {
    (, bytes memory _value) = _get(keccak256(abiEncodedKeys));
    return abi.decode(_value, (bool));
  }

  function get(bytes memory abiEncodedKeys, int256 _type) public returns(int256 value) {
    (, bytes memory _value) = _get(keccak256(abiEncodedKeys));
    return abi.decode(_value, (int256));
  }

  function _get(bytes32 key) public returns(bool ok, bytes memory value) {
    Stored storage s = storageHub[key]; 
    if (s.tf) {
      return (s.tf, s.data);
    } else if (address(parent) == address(0x0)) {
      return (false, value); // value is blank
    }
    (ok, value) = parent._get(key); // this chained "get" is the crux of this design
    if (ok) {
      _set(key, value); // now set this ancestor's value to this level
    }
    return (ok, value);
  }

}
