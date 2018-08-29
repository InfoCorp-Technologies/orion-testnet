pragma solidity ^0.4.23;

contract Validator {
    
    address[] private validatorArr;
    address[] private pendingArr;
    bool private operation_set = false;
    bool public finalized = true;
    mapping (address => uint) validatorMap;

    event InitiateChange(bytes32 indexed parent_hash, address[] new_set);
    event ChangeFinalized(address[] current_set);

    modifier is_finalized {
        require(finalized);
        _;
    }
    
    modifier is_validator {
        require(validatorMap[msg.sender] > 0);
        _;
    }

    constructor(address[] init) public {
        validatorArr = pendingArr = init;
        for (uint i = 0; i < validatorArr.length; i++) {
            validatorMap[validatorArr[i]] = i+1;
        }
    }

    // Called on every block to update node validator list.
    function isValidator(address addr) external view returns(bool) {
        return validatorMap[addr] > 0;
    }
    
    function getValidators() public constant returns (address[]) {
        return validatorArr;
    }
    
    function getPendings() public constant returns (address[]) {
        return pendingArr;
    }
    
    // Expand the list of validators.
    function addValidator(address _newValidator) public is_finalized is_validator {
        validatorMap[_newValidator] = pendingArr.length;
        pendingArr.push(_newValidator);
        initiateChange();
    }

    // Remove a validator from the list.
    function removeValidator(address _oldValidator) public is_finalized is_validator {
        uint index = validatorMap[_oldValidator]-1;
        uint last = pendingArr.length-1;
        validatorMap[_oldValidator] = 0;
        validatorMap[pendingArr[last]] = index+1;
        pendingArr[index] = pendingArr[last];
        pendingArr.length--;
        initiateChange();
    }

    function initiateChange() private {
        finalized = false;
        emit InitiateChange(blockhash(block.number - 1), pendingArr);
    }

    function finalizeChange() public {
        require(!finalized);
        validatorArr = pendingArr;
        finalized = true;
        emit ChangeFinalized(validatorArr);
    }
}