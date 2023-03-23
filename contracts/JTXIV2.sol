// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import  './JTXI.sol';
contract JTXV2 is JTXI{

    function version()pure public returns(string memory){
          return "v2";
    }

}