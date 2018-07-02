pragma solidity ^0.4.20;

import "../Ownable.sol";

contract Oracle is Ownable {
    
    struct QueryInfo {
        bool isWaiting;
        address caller;
        string result;
    }
    
    uint currentId;
    address public bridge = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    
    mapping(bytes => string) apiMap;
    mapping(uint => QueryInfo) queryMap;

    event Query(uint queryid, string url);
    event Result(uint queryid, address user);

    constructor() public {
        apiMap["user"] = "http://104.211.59.231/user/";
        apiMap["attestator"] = "http://104.211.59.231/attestator";
        apiMap["livestock"] = "http://104.211.59.231/livestock";
    }

    function __callback(uint myid, string result) public {
        require(queryMap[myid].isWaiting);
        require(msg.sender == bridge);
        queryMap[myid].isWaiting = false;
        queryMap[myid].result = result;
        emit Result(myid, queryMap[myid].caller);
    }
    
    function api(string name) view external returns(string) {
        bytes memory interfaces = bytes(name);
        return apiMap[interfaces];
    }
    
    function query(string name, string walletaddress) external {
        bytes memory interfaces = bytes(name);
        string memory url = strConcat(apiMap[interfaces], walletaddress);
        currentId++;
        queryMap[currentId].caller = msg.sender;
        queryMap[currentId].isWaiting = true;
        emit Query(currentId, url);
    }
    
    function result(uint myid) view external returns(string) {
        require(queryMap[myid].caller == msg.sender);
        require(!queryMap[myid].isWaiting);
        return queryMap[myid].result;
    }
    
    function setAPI(string _name, string _api) external onlyOwner {
        bytes memory interfaces = bytes(_name);
        apiMap[interfaces] = _api;
    }
    
    function strConcat(string _a, string _b) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory abcde = new string(_ba.length + _bb.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        return string(babcde);
    }
}