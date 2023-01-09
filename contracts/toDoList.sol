//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract  ToDoList{
    struct Todo{// Yapılacaklar listesinin tutulacağı struct veri yapısı.
        string text;// Yapılacak işlerin tutulacağı alan.
        bool completed;// İşin tamamlanıp tamamlanmadığını gösteren alan.
    }

    Todo [] public todos;

    function create(string calldata _text) external{ // Yeni bir yapılacak iş ekle.
        todos.push(Todo({ // Struct yapısına ekle.
            text : _text,  // Yapılacak işin adı.
            completed : false // Default olarak tamamlanmadı şeklinde eklenir.
        }));

    }

    function updateText(uint _index, string calldata _text, bool _isComplete) external{ // Veri yapısındaki bir işi güncelle.
        todos[_index].text = _text; // Verilen indexteki stringi parametreyle güncelle.
        todos[_index].completed = _isComplete; // Güncellenen yapılacak iş tamamlanmış mı ? isComplete parametresiyle bunu öğren.
    }

    function get(uint _index) public view returns (string memory text, bool completed) {// İndexi verilen işin tanımını ve tamamlanma durumunu görüntüle.
        Todo memory todo = todos[_index]; 
        return (todo.text, todo.completed); 
    }

    function toggleCompleted(uint _index) public { // Verilen indexteki işi tamamlandı veya tamamlanmadı olarak işaretle.
        Todo storage todo = todos[_index];
        todo.completed = !todo.completed;
    }
}


