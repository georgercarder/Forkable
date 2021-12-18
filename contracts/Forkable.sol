//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Types {
  uint256 public UINT256_TYPE;
  bytes32 public BYTES32_TYPE;
  bool public BOOL_TYPE;
  int256 public INT256_TYPE;
} // to induce choice of overloaded functions

contract ForkableStorage {

  Forkable public parent;
  // bound is to add more control over data retrieved from ancestors
  uint256 public timeBound; 

  // forker -> time of forking
  mapping( address => uint256 ) internal forkers;

  // k -> v
  mapping( bytes32 => Stored ) internal storageHub;

  // k -> archivedTimestamps
  mapping( bytes32 => uint256[] ) internal archivedTimestamps;
  // k -> timestamp -> v
  mapping( bytes32 => mapping( uint256 => bytes)) internal archivedStorage;

  struct Stored {
    uint256 timestamp; // age of data may be a factor
    bytes data;
  }

}

contract Forkable is ForkableStorage, Types {

  function fork() external {
    forkers[msg.sender] = block.timestamp;
  }

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
    if (storageHub[key].timestamp == 0) { // if never set
      storageHub[key] = Stored({timestamp: block.timestamp, data: value}); 
    }
    // else no op
  }

  function _set(bytes32 key, bytes memory value, uint256 timestamp) private {
    if (storageHub[key].timestamp == 0) { // if never set
      storageHub[key] = Stored({timestamp: timestamp, data: value}); 
    }
  }

  /* // need to figure out how this would be disambiguated from uint256...
  function set(bytes memory abiEncodedKeys, int256 value) internal {
    storageHub[keccak256(abiEncodedKeys)] = Stored({timestamp: block.timestamp, data: abi.encode(value)}); 
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
    // archive
    Stored storage s = storageHub[key];
    archivedTimestamps[key].push(s.timestamp);
    archivedStorage[key][s.timestamp] = s.data;
    // store new data
    storageHub[key] = Stored({timestamp: block.timestamp, data: value}); 
  }

  // GETTERS

  function get(bytes memory abiEncodedKeys) public returns(bytes memory value) {
    (, value) = _hashAndGet(abiEncodedKeys);
    return value; 
  }

  function get(bytes memory abiEncodedKeys, uint256 _type) public returns(uint256 value) {
    (bool ok, bytes memory _value) = _hashAndGet(abiEncodedKeys);
    if (ok) {
      return abi.decode(_value, (uint256));
    }
    return value; // empty
  }

  function get(bytes memory abiEncodedKeys, bytes32 _type) public returns(bytes32 value) {
    (bool ok, bytes memory _value) = _hashAndGet(abiEncodedKeys);
    if (ok) {
      return abi.decode(_value, (bytes32));
    }
    return value; // empty
  }

  function get(bytes memory abiEncodedKeys, bool _type) public returns(bool value) {
    (bool ok, bytes memory _value) = _hashAndGet(abiEncodedKeys);
    if (ok) {
      return abi.decode(_value, (bool));
    }
    return value; // empty
  }

  function get(bytes memory abiEncodedKeys, int256 _type) public returns(int256 value) {
    (bool ok, bytes memory _value) = _hashAndGet(abiEncodedKeys);
    if (ok) {
      return abi.decode(_value, (int256));
    }
    return value; // empty
  }

  function _get(bytes32 key) public returns(uint256 timestamp, bytes memory value) {
    if (forkers[msg.sender]>0) { // means caller is a forker
      return _getRestricted(key);
    } 
    // else
    return _getUnrestricted(key);
  }

  function _getRestricted(bytes32 key) public returns(uint256 timestamp, bytes memory value) {
    uint256 timeOfForking = forkers[msg.sender]; 
    Stored storage s = storageHub[key]; 
    if (s.timestamp > 0 && s.timestamp <= timeOfForking) { // it locally exists
      return (s.timestamp, s.data);
    } else if (s.timestamp > timeOfForking) { // guaranteed to be archived
      // get archived
      uint256 archivedTimestamp = searchForArchivedTimestamp(key, timeOfForking);
      if (archivedTimestamp > 0) {
        return (archivedTimestamp, archivedStorage[key][archivedTimestamp]); 
      }
    } else if (address(parent) == address(0x0)) {
      return (0, value); // value is blank
    }
    (timestamp, value) = parent._get(key); // this chained "get" is the crux of this design
    if (timestamp == 0) { // data DNE or is set/updated in ancestors after fork
      bytes memory empty;
      return (0, empty);
    }
    _set(key, value, timestamp); // now set this ancestor's value to this level
    if (timestamp > timeOfForking) { // this data cannot be served to the caller since its after forking
      bytes memory empty;
      return (0, empty);
    }
    return (timestamp, value);
  }

  function _getUnrestricted(bytes32 key) public returns(uint256 timestamp, bytes memory value) {
    Stored storage s = storageHub[key]; 
    if (s.timestamp > 0) { // it locally exists, and the timeBound is irrelevant
      return (s.timestamp, s.data);
    } else if (address(parent) == address(0x0)) {
      return (0, value); // value is blank
    }
    (timestamp, value) = parent._get(key); // this chained "get" is the crux of this design
    if (timestamp == 0) { // data DNE or is set/updated in ancestors after fork
      bytes memory empty;
      return (0, empty);
    }
    _set(key, value, timestamp); // now set this ancestor's value to this level
    return (timestamp, value);
  }

  function _hashAndGet(bytes memory abiEncodedKeys) private returns(bool ok, bytes memory value) {
    (uint256 timestamp, bytes memory _value) =  _get(keccak256(abiEncodedKeys));
    if (timestamp > 0) {
      ok = true;
    }
    return (ok, _value);
  }

  function searchForArchivedTimestamp(bytes32 key, uint256 timeOfForking) private returns(uint256 archivedTimestamp) {
    uint256[] storage ats = archivedTimestamps[key];
    // goal: archivedTimestamp <= timeOfForking // as close as possible

    archivedTimestamp = ats[0];
    if (archivedTimestamp > timeOfForking) { // means all archivedTimestamps are too new
      archivedTimestamp = 0;
      return archivedTimestamp;
    }
    if (archivedTimestamp == timeOfForking) { // we have exactly what we want
      return archivedTimestamp;
    }
    // means archivedTimestamp < timeOfForking
    /// search! grr
    // use inefficient search for proof of concept but update this with something more efficient
    uint256 searcher;
    for (uint256 i=1; i<ats.length; i++) {
      searcher = ats[i]; 
      if (searcher > timeOfForking) {break;}
      archivedTimestamp = searcher;
    }
    return archivedTimestamp;
  }

}

    /*archivedTimestamp = ats.at(ats.length()-1); // unchecked but guaranteed length>0
    bool searchHigh = false;
    uint256 half = ats.length()/2;
    uint256 quarter = half/2;
    uint256 tmp;
    while(archivedTimestamp > timeOfForking) {
      archivedTimestamp = ats.at(half); 
      if (archivedTimestamp == timeOfForking) {
        break; 
      }
      if (archivedTimestamp < timeOfForking) {
        searchHigh = true;
        tmp = ats.at(half+quarter);

      } else {
      
      }
      // check comparison
    }*/
