//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract etherStore{
    address public owner;
    uint256 public balance;

    constructor (){
        owner = msg.sender; // Kontratı çağıran adresi owner değişkenine ata.
    }
    receive() payable external{ // Ödeme almak için fonksiyon.
        balance += msg.value; // Kontratı çağıran adresin varlıkları kadar balance değişkenini arttır.
    }
    function withdraw(uint256 amount, address payable destAddr) public{ // Para çekme işlemi için fonksiyon. Miktar ve hedef adres parametreleri.
        require(msg.sender == owner, "Only owner can withdraw."); // Sadece kontratı çağıran kişi para çekebilir.
        require(amount<=balance, "Insufficient funds."); // Varolan miktardan fazlası çekilemez.

        destAddr.transfer(amount); // Hedef adrese amount parametresi kadar varlık gönder.
        balance -= amount; // Bakiyeyi gönderilen varlık kadar azalt.
    }

}