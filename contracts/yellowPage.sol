//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";


contract AdFieldRental{
    address payable private owner; // Owner of the site. To be set later in the constructor
    uint256 rentPrice; // Fixed rent price. To be set later in the constructor
    uint256 totalBalance; // Total balance of the contract
    
    struct AdField { // Ad field struct
        string title;
        string description;
        uint256 price;
        address renter;
        uint256 rentStart;
        uint256 rentEnd;
        bool rented;
    }

    mapping(uint256 => AdField) public adFields; // Mapping to track adFields
    mapping(address => uint256) public rentedFields; //  Mapping to track rentedFields
    mapping(address => uint256) public rentalCosts; // Mapping to track rentalCosts

    // Events to emit logs
    event FieldRented(address indexed renter, uint256 indexed id);
    event RentalCancelled(address indexed renter, uint256 indexed id);
    event FieldUpdated(address renter, uint256 indexed id);
    event Withdraw(AdField field, uint256 amount);

    // Initialize ad fields with default values
    constructor ()  {
        owner = payable(msg.sender); // Ad site owner is the deployer of this contract
        for (uint256 i = 0; i < 16; i++) {
            adFields[i] = AdField("For Sale", "1 ETH / day", 0, address(0), 0, 0, false); // Fixed number of 16 ad fields
        }
        rentPrice = 2 ether; // Fixed rent price for 1 day
    }

    modifier onlyOwner(){ // Operations that can only be done by the owner
        require(msg.sender == owner, "Only the owner can do this operation");
        _;
    }

    modifier onylRenter(uint256 _id){ // Operations that can only be done by the owner
        require(msg.sender == adFields[_id].renter , "Only the renter can do this operation");
        _;
    }
    
    modifier onlyAvailable(uint256 _id) { // Check if the fields are available
        require(adFields[_id].renter == address(0), "Field is already rented"); // Check if the field has already rented
        require(rentedFields[msg.sender] == 0, "You already rented a field"); // Users can not rent multiple ad fields
        _;
    }

    // Rent an ad field
    function rentField(uint256 _id, uint256 _day, string memory _title, string memory _description, uint256 _price) external payable onlyAvailable(_id){
        require(msg.value >= rentPrice * _day, "Not enough ETH provided"); // Check if there is enough balance to cover the cost
 
        adFields[_id].renter = msg.sender; // Set renter's address to msg.sender
        updateField(_id, _title, _description, _price); // Set the ad field's title, description and price. Price is the object's price for sale on the ad
        
        adFields[_id].rentStart = block.timestamp; // Rent start time
        adFields[_id].rentEnd = block.timestamp + _day * 1 days; // Rent end time
        rentedFields[msg.sender] = _id; // Add the field to rentedFields list
        adFields[_id].rented = true; // Set the field rented varible to true

        rentalCosts[msg.sender] += rentPrice * _day; // Calculate total rent cost
        totalBalance += rentPrice * _day; // Increase contract balance to keep track
        
        emit FieldRented(msg.sender, _id);
    }

    function calculateRefund(uint256 id) internal view returns (uint256) { // Calculate refund amount. If the renter cancels early, amount for remaining days will be refunded
        uint256 daysLeft = (adFields[id].rentEnd - block.timestamp) / 1 days;

        console.log(rentPrice*daysLeft);
        return rentPrice * daysLeft;
    }
    
    function cancelRental(uint256 _id) external payable onylRenter(_id) { // Cancel rental and refund for remaining days

        uint256 refundAmount = calculateRefund(_id); // Calculate refund amount
        payable(msg.sender).transfer(refundAmount); // Transfer calculated amount

        totalBalance -= refundAmount; // Decrease total balance of the contract
        adFields[_id] = AdField("For Sale", "1 ETH / day", 0, address(0), 0, 0, false); // Reset ad field
        rentedFields[msg.sender] = 0; // Set the field rented from msg.sender to 0
        rentalCosts[msg.sender] -= refundAmount; // Decrease the refund amount from the total cost of rent

        emit RentalCancelled(msg.sender, _id);
    }

    // Update ad field details
    function updateField(uint256 _id, string memory _title, string memory _description, uint256 _price) public { // Renter can update the ad fields to adjust price title and so on
        require(adFields[_id].renter == msg.sender, "You are not the renter of this field");

        adFields[_id].title = _title;
        adFields[_id].description = _description;
        adFields[_id].price = _price;

        emit FieldUpdated(msg.sender, _id);
    }

    // Withdraw function for site owner
    function withdraw(uint256 _id) public onlyOwner() {
        require(adFields[_id].rented == false, "Rental period has not ended yet"); // Owner can only withdraw if the the field is not on rent anymore. 
        //This is to prevent the contract from not having enough balance to refund if the rent is cancelled early

        uint256 amount = rentalCosts[adFields[_id].renter]; // Get the amount earned from the rent

        owner.transfer(amount); // Transfer the amount to owner
        totalBalance -= amount; // Decrease the total balance of the contract

        emit Withdraw(adFields[_id], amount);
    }

    function getBalance() public view returns (uint) {
        return totalBalance;
    }

}