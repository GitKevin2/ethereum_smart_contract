//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

/** 
    Node is an object holding its represented address, previous address and next address
 */
struct Node {
    address current;
    address next;
    address prev;
}

/**
    NodeList together with Nodes library serves as a doubly linked list chaining Nodes together using a mapping as storage and addresses as keys to iterate from
    one node to the next. Its main operations take O(1) time and it doesn't depend on indices but has the overhead of using structs/objects as linked lists do.

    The usage of a library and struct reduces gas costs and avoids requiring a contract implementation of it.
    include 'using Nodes for NodeList' in your contract.
 */
struct NodeList {
    mapping(address => Node) nodes;
    address _head;
    address _tail;
    Counters.Counter _numNodes; //uses Counters.Counter to avoid easy direct access and reassignment to counter.
}

library Nodes {

    using Counters for Counters.Counter;

    event Stored(address indexed lastInserted);
    event Removed(address indexed lastRemoved);

    function push(NodeList storage list, address value) internal {
        require(value != address(0), "NodeList: Cannot use zero-address");
        require(!has(list, value), "NodeList: address already exists in list");

        list.nodes[value] = newNode(value);

        if(count(list) == 0) {
            list._head = value;
            list._tail = value;
        }
        else {
            join(list.nodes[list._tail], list.nodes[value]);
            list._tail = value;
        }
        list._numNodes.increment();
        emit Stored(value);
    }

    function push(NodeList storage list, address[] memory values) internal {
        for(uint i; i < values.length; i++) {
            address value = values[i];
            require(value != address(0), "NodeList: Cannot use zero-address");
            require(!has(list, value), "NodeList: address already exists in list");

            list.nodes[value] = newNode(value);

            if(start(list) == address(0)) {
                list._head = value;
                list._tail = value;
            }
            else {
                join(list.nodes[list._tail], list.nodes[value]);
                list._tail = value;
            }
            emit Stored(value);
        }
        list._numNodes._value = count(list) + values.length; // violates practice of Counter but is more cost efficient
    }

    function start(NodeList storage list) internal view returns (address) {
        return list._head;
    }

    function end(NodeList storage list) internal view returns (address) {
        return list._tail;
    }

    function getNode(NodeList storage list, address value) internal view returns (Node memory) {
        return list.nodes[value];
    }

    function remove(NodeList storage list, address value) internal {
        if(count(list) == 0) return;
        if (list._head == list._tail && value == list._head) {
            delete list._head;
            delete list._tail;
        }
        else if (value == list._head) {
            list._head = next(list, list._head);
            delete list.nodes[list._head].prev;
        }
        else if (value == list._tail) {
            list._tail = previous(list, list._tail);
            delete list.nodes[list._tail].next;
        }
        else {
            Node storage node = list.nodes[value];
            join (list.nodes[node.prev], list.nodes[node.next]);
        }
        delete list.nodes[value];
        list._numNodes.decrement();
        emit Removed(value);
    }

    function pop(NodeList storage list) internal {
        address prev = list.nodes[end(list)].prev;
        delete list.nodes[prev].next;
        delete list.nodes[end(list)];
        emit Removed(end(list));
        
        list._tail = prev;
        list._numNodes.decrement();
    }

    function count(NodeList storage list) internal view returns (uint) {
        return list._numNodes.current();
    }

    function next(NodeList storage list, address current) internal view returns (address) {
        return list.nodes[current].next;
    }

    function previous(NodeList storage list, address current) internal view returns (address) {
        return list.nodes[current].prev;
    }

    function has(NodeList storage list, address value) internal view returns (bool) {
        require(value != address(0), "NodeList: zero-address is an invalid address");
        return list.nodes[value].current == value;
    }

    function toArray(NodeList storage list) internal view returns (address[] memory $array) {
        uint i; $array = new address[](count(list));
        for (address p = start(list); p != address(0); p = next(list, p)) $array[i++] = p;

    }

    function join(Node storage a, Node storage b) private {
        a.next = b.current;
        b.prev = a.current;
    }

    function joined(Node memory a, Node memory b) internal pure returns (Node memory, Node memory) {
        a.next = b.current;
        b.prev = a.current;
        return (a, b);
    }

    function newNode(address value) private pure returns (Node memory) {
        return Node({current: value, next: address(0), prev: address(0)});
    }
}


