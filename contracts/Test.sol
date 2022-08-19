//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './helpers/NodeList.sol';
import 'hardhat/console.sol';

abstract contract NodeListContract {
    NodeList list;
    uint initialGas;
    uint finalGas;

    constructor(address[] memory owners) {
        initialGas = gasleft();
        push(owners);
        finalGas = gasleft();
        
    }

    function gasInit() external view returns (uint) {
        return initialGas;
    }

    function gasLeft() external view returns (uint) {
        return gasleft();
    }

    function gasUsed() external view returns (uint) {
        return initialGas - finalGas;
    }

    function gasPrice() external view returns (uint) {
        return tx.gasprice;
    }

    function push(address[] memory owners) public virtual;
}

contract NodeListContract1 is NodeListContract {
    using Nodes for NodeList;
    constructor(address[] memory owners) NodeListContract(owners) {

    }

    function push(address[] memory owners) public override {
        initialGas = gasleft();

        for(uint i; i < owners.length; i++) {
            list.push(owners[i]);
        }
    }

}

contract NodeListContract2 is NodeListContract {
    using Nodes for NodeList;
    constructor(address[] memory owners) NodeListContract(owners) {
        //list.push(owners);
    }

    function push(address[] memory owners) public override {
        initialGas = gasleft();
        list.push(owners);
    }
}

