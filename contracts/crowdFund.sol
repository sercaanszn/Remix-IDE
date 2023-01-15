//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IERC20 { // IERC20 protocol
    function transfer(address, uint) external returns (bool);

    function transferFrom(
        address,
        address,
        uint
    ) external returns (bool);
}


contract CrowdFund{
    event Launch( // Launch a new CrowdFund
        uint id,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );
    // Events
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint id, address indexed caller, uint amount);


    struct Campaign{ // Start a campaign
        address creator;
        uint goal;  // goal
        uint pledged; // Pledged amount
        uint32 startAt; // Start date
        uint32 endAt; // End date
        bool claimed; // Claimed amount

    }

    IERC20 public immutable token;
    uint public count;

    // Mappings for campaigns and pledges amounts
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address=>uint)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }

    // Launch a new campaign
    function launch(uint _goal, uint32 _startAt, uint32 _endAt) external{
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt >= _startAt, "end at < start at");
        require(_endAt <= block.timestamp + 90 days, "end at > max duration");

        count +=1;

        campaigns[count] = Campaign({
            creator : msg.sender,
            goal : _goal,
            pledged : 0,
            startAt : _startAt,
            endAt : _endAt,
            claimed : false
        });

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }
    // Cancel campaign
    function cancel(uint _id) external{
        Campaign memory campaign = campaigns[_id];
        require( campaign.creator == msg.sender, "not creator"); // only creator can cancel
        require(block.timestamp < campaign.startAt, "started"); // if it is already started, cannot be canceled.
        delete campaigns[_id];
        emit Cancel(_id);
    }
    // Pledge money
    function pledge(uint _id, uint _amount) external{
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "not started"); // Only pledge if campaign has started
        require(block.timestamp <= campaign.endAt, "ended"); // Only pledge if campaign has not ended

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount; 
        token.transferFrom(msg.sender, address(this), _amount);// pledge given amount to campaign

        emit Pledge(_id, msg.sender, _amount);
    }
    // Unpledge money
    function unpledge(uint _id, uint _amount) external{
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "ended"); // Omly unpledge if campaign has not ended
        
        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount); // Transfer back the pledged amount to message sender.

        emit Unpledge(_id, msg.sender, _amount);
    }
    // Claim money
    function claim(uint _id) external{
        Campaign storage campaign = campaigns[_id];
        require(campaign.creator == msg.sender, "not creator"); // only creator can claim the pledged amounts
        require(block.timestamp > campaign.endAt, "not ended"); // only claimable after the campaign has ended
        require(campaign.pledged >= campaign.goal, "pledged < goal"); // Pledged amount should be equal or higher than the goal
        require(!campaign.claimed, "claimed"); // If already claimed, cannot claim

        campaign.claimed = true;
        token.transfer(campaign.creator, campaign.pledged); // transfer claimed amount to creator

        emit Claim(_id);
    }
    // Refund if canceled
    function refund(uint _id) external{
        Campaign memory campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "not ended"); // If not ended cannot refund
        require(campaign.pledged < campaign.goal, "pledged >= goal"); // If the goal is reached cannot refund
        
        uint bal = pledgedAmount[_id][msg.sender]; // total pledged amount of the message sender
        pledgedAmount[_id][msg.sender] = 0; // reset pledged amount bc it will be refunded
        token.transfer(msg.sender, bal); // transfer back pledged amount

        emit Refund(_id, msg.sender, bal);
    }
    

}