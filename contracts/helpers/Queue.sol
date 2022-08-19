//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

struct AddressQueue {
    mapping(address => address) _next;
    address _front;
    address _back;
}

struct UIntQueue {
    mapping(uint256 => uint256) _next;
    uint256 _front;
    uint256 _back;
}

library Queues {

    function front(AddressQueue storage queue) internal view returns (address) {
        return queue._front;
    }

    function front(UIntQueue storage queue) internal view returns (uint256) {
        return queue._front;
    }

    function back(AddressQueue storage queue) internal view returns (address) {
        return queue._back;
    }

    function back(UIntQueue storage queue) internal view returns (uint256) {
        return queue._back;
    }

    function next(AddressQueue storage queue, address value) internal view returns (address) {
        return queue._next[value];
    }

    function next(UIntQueue storage queue, uint value) internal view returns (uint256) {
        return queue._next[value];
    }

    function has(AddressQueue storage queue, address value) internal view returns (bool) {
        return value == front(queue) || value == back(queue) || queue._next[value] != address(0);
    }

    function has(UIntQueue storage queue, uint value) internal view returns (bool) {
        return value == front(queue) || value == back(queue) || queue._next[value] != 0;
    }

    function enqueue(AddressQueue storage queue, address value) internal {
        require(value != address(0), "AddressQueue: zero address is not valid.");
        if(front(queue) == address(0)) {
            queue._front = value;
            queue._back  = value;
        }
        else {
            queue._next[queue._back] = value;
            queue._back = value;
        }
    }

    function enqueue(UIntQueue storage queue, uint256 value) internal {
        require(value != 0, "UIntQueue: use queue for uint IDs, zero is not valid ID.");
        if(front(queue) == 0) {
            queue._front = value;
            queue._back  = value;
        }
        else {
            queue._next[queue._back] = value;
            queue._back = value;
        }
    }

    function dequeue(AddressQueue storage queue) internal returns (address) {
        if (front(queue) == address(0)) return address(0);
        address oldFront = front(queue);
        queue._front = queue._next[oldFront];
        delete queue._next[oldFront];
        if(oldFront == back(queue)) delete queue._back;
        return oldFront;
    }

    function dequeue(UIntQueue storage queue) internal returns(uint256) {
        if(front(queue) == 0) return 0;
        uint oldFront = front(queue);
        queue._front = queue._next[oldFront];
        delete queue._next[oldFront];
        if(oldFront == back(queue)) delete queue._back;
        return oldFront;
    }

}


