// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlockTemp {
  event tempUpdate(uint256 lastId, uint256 temp);
  
  struct Temp {
    uint latestTimestamp;
    uint temp;
  }
  mapping(uint => Temp) public tempData;
  mapping(address => uint) public pointMap;
  mapping(address => bool) public blockMap;
  // Contract owner
  address public owner;
  uint8 public decimal = 2;
  uint[] tempCache;
  address[] addrCache;
  uint public lastId;

  constructor() public {
    owner = msg.sender;
  }

  /**
    * @notice setTemp is used to set the temperature by providing nodes client
    */
  function setTemp(uint t) public {
    require(tempCache.length <= 10, "over max set temperature length");
    require(blockMap[msg.sender] == false, "ban address not allow");
    tempCache.push(t*100);
    addrCache.push(msg.sender);
  }

  /**
    * @notice getLastTemp is used to get the last temperature
    * @return temp result.
    */
  function getLastTemp() view public returns (uint) {
    return tempData[lastId].temp;
  }

  /**
    * @notice getABS is used to get the absolute value of a number
    */
  function getABS(uint a) private pure returns(uint) {
    return (a <= 0) ? (0 - a) : a;
  }

  /**
    * @notice mergeTemp is used to merge temperature with fixed time interval merge. 
    * point is a rule to reward and punish temperature providing nodes
    */
  function mergeTemp() public onlyOwner {
    require(tempCache.length < 1, "not enough temperature cache seted");
    uint totalTemp;
    for (uint i; i<tempCache.length;++i) {
      totalTemp+=tempCache[i];
    }

    lastId += 1;
    Temp memory _temp;
    _temp.latestTimestamp = block.timestamp;
    _temp.temp = totalTemp / tempCache.length;
    tempData[lastId] = _temp;

    // reward 1 point deviation less than 5
    // punish 1 point deviation more than 5 less than 10
    // ban address deviation more than 10 
    for (uint i; i<tempCache.length;++i) {
      uint abs = getABS(tempCache[i] - _temp.temp);
      if (abs <= 5) {
        pointMap[addrCache[i]] += 1;
      } else if (abs > 5 && abs <= 10){
        if (pointMap[addrCache[i]] > 0) {
          pointMap[addrCache[i]] -= 1;
        }
      } else if (abs > 10) {
        blockMap[addrCache[i]] == true;
      }
    }

    // clear tempCache and addrCache
    emit tempUpdate(lastId, _temp.temp);
  }

  /**
    * @notice onlyOwner is used to makesure sender is admin address
    */
  modifier onlyOwner() {
    require(msg.sender == owner, "Ownable: caller is not the owner");
    _;
  }

}
