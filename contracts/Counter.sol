//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Counter {
    uint public count; //sayaç değişkeni

    function increment() external{ // 1 arttır.
        count+=1;
        
    }

    function decrement() external{ // 1 azalt.
        count-=1;
        
    }
    
}