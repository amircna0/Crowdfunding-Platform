// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18 ;
// this projects target is modified for the projects with good ideas to produce but they don't have investment money or getting loan 
contract  crowdfunding {
    
    address public investors ; // contributors 
    address public admin ;  
    uint256 public investors_values ;  //contributors wallet value 
    uint256 public goal ; 
    uint256 public community;//how many contributors or inestors
    uint256 public deadline ; 
    uint256 public raisedamount ;//contibutors additional money 

    struct quest{
        string description ; // the spending request reason . 
        address payable recipient ; 
        uint256 value ; 
        bool completed ; 
        uint256 num_voters;
        mapping (address=>bool) voters ; 
    }
    event InvestEvent(address _sender , uint256 _value ) ;
    event RequestEvent(string _description , address _recipient , uint256 _value);
    event PaymentEvent(address _sender , uint256 _value) ; 

    mapping (uint256=>quest) public requests ;   // we see our requests 
    uint256 public num_requests ; // we cannot call something like index in mapping so we should use something to use instead of index 

    mapping (address=>uint256) public investment ;
    
    constructor(uint256 _deadline ,uint256 _goal){
        deadline = block.timestamp + _deadline ; 
        goal = _goal ;
        investors_values = 100 wei ; 
        admin = payable(msg.sender) ; 
    }

    function invest() payable public {
        require(msg.value >= investors_values, "minimum contribution not met .") ; 
        require(block.timestamp < deadline , "deadline has passed .");
        if (investment[msg.sender] == 0 ){
            community ++ ;  
        }
        investment[msg.sender] += msg.value ; 
        raisedamount += msg.value ; 
        emit InvestEvent(msg.sender, msg.value);
    }
    receive() external payable { 
        invest();
    }
    function getbalance() public view returns(uint256){
        return address(this).balance ; 
    }
    function refund () public {
        require(block.timestamp > deadline && raisedamount<goal ) ;
        require(investment[msg.sender] > 0 );//this means this contract has sent money to contract so it's for the investors whos balance is +  
        address payable recipient ; 
        recipient = payable (msg.sender) ; 
        uint256 value = investment[msg.sender] ; 
        investment[msg.sender] = 0 ;
        recipient.transfer(value);           
    }
    modifier only_admin() {
        require (msg.sender == admin);
        _; 
    }
    function creating_requests (uint256 _value , address payable  _recipient ,string memory _description ) public only_admin {
        quest storage new_request = requests[num_requests] ;
        num_requests++;

        new_request.description = _description ;
        new_request.value = _value ;
        new_request.recipient = _recipient ;
        new_request.completed = false ; 
        new_request.num_voters = 0 ; 
        emit RequestEvent(_description, _recipient, _value);
    } 
    function voting(uint256 request_num) public {
        require(investment[msg.sender] > 0  );
        quest storage this_request = requests[request_num]  ; 
        require(this_request.voters[msg.sender] == false,"you have already voted" );
        this_request.voters[msg.sender] = true ; 
        this_request.num_voters++ ;

    }
    function payment (uint256 request_num) public only_admin{
        require (raisedamount > goal) ; 
        quest storage this_request = requests[request_num];
        require(this_request.completed == false , "this request has been completed ");
        require(this_request.num_voters > community / 2 ) ; 
        this_request.recipient.transfer(this_request.value);
        this_request.completed = true ; 
        emit PaymentEvent(this_request.recipient, this_request.value);
    }
}