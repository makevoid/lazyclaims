/*
Copyright (C) 2015 Thomas Bertani - Oraclize srl
*/



// https://www.oraclize.it/service/api
contract OraclizeI {
    function query(uint timestamp, byte[] formula_1, byte[] formula_2, byte[] formula_3, byte[] formula_4){}
    function query(uint timestamp, address param, byte[] formula_1, byte[] formula_2, byte[] formula_3, byte[] formula_4){}
}



contract Insurance {
  // logging helper
  event Log(uint k);

  address[5] public users_list;
  uint public users_list_length;
  mapping (address => uint) public users_balance;
  
  address[5] public investors_list;
  uint public investors_list_length;
  mapping (address => uint) public investors_invested;
  

  // just a function to send the funds back to the sending address, another option would be to STOP execution by throwing an exception here
  function RETURN(){
    msg.sender.send(msg.value);
  }

  // FALLBACK function
  function(){
    if (msg.sender == address(0x26588a9301b0428d95e6fc3a5024fce8bec12d51)) callback();
  }
  
  // registers a new user
  function register(byte[] formula_1a, byte[] flight_number, byte[] formula_3a, byte[] formula_4a, byte[] formula_4b, uint arrivaltime){
    if (uint(msg.value) == 0) return; // you didn't send us any money
    if (now > arrivaltime-2*24*3600){ RETURN(); return; } // refuse new insurances if arrivaltime < 2d from now
    if (users_list_length > 4){ RETURN(); return; } // supporting max 5 users for now
    if (users_balance[msg.sender] > 0){ RETURN(); return; } // don't register twice!
    uint balance_busy = 0;
    for (uint k=0; k<users_list_length; k++){
        balance_busy += 5*users_balance[users_list[k]];
    }
    if (uint(address(this).balance)-balance_busy < 5*uint(msg.value)){ RETURN(); return; } // don't have enough funds to cover your insurance
    // ORACLIZE CALL
    OraclizeI oracle = OraclizeI(0x393519c01e80b188d326d461e4639bc0e3f62af0);
    oracle.query(arrivaltime+3*3600, msg.sender, formula_1a, flight_number, formula_3a, formula_4a);
    uint160 sender_b = uint160(msg.sender);
    oracle.query(arrivaltime+3*3600, address(++sender_b), formula_1a, flight_number, formula_3a, formula_4b);
    //
    delete users_balance[msg.sender];
    users_balance[msg.sender] = msg.value;
    users_list[users_list_length] = msg.sender;
    users_list_length++;
  }
  
  // Oraclize callback
  function callback(){
    uint160 sender_;
    for (uint j=0; j<20; j++){
        sender_ *= 256;
        sender_ += uint160(msg.data[j]);
    } 
    address sender = address(sender_);
    uint sender_b_ = uint160(sender);
    sender_b_--;
    address sender_b = address(sender_b_);
    uint status = 0;
    if (users_balance[sender_b] > 0){ // status = 1
      status = 1;
      uint balance = users_balance[sender_b];
      delete users_balance[sender_b];
    } else {
      delete users_balance[sender];
    }
    if ((users_balance[sender_b] > 0)&&(status == 1)) sender.send(balance*5);
    for (uint k=0; k<users_list_length; k++){
        if ((users_list[k] == sender)||(users_list[k] == sender_b)){
            users_list[k] = 0x0;
        }
    }
  }
  
  // invest new funds
  function invest() {
    if (investors_invested[msg.sender] == 0){
      investors_list[investors_list_length] = msg.sender;
      investors_list_length++;
    }
    investors_invested[msg.sender] += uint(msg.value);
  }
  
  // deinvest funds
  function deinvest(){
    if (investors_invested[msg.sender] == 0) return;
    uint balance_busy = 0;
    for (uint k=0; k<users_list_length; k++){
      balance_busy += 5*users_balance[users_list[k]];
    }
    uint invested_total = 0;
    for (k=0; k<investors_list_length; k++){
      invested_total += investors_invested[investors_list[k]];
    }
    uint gain = investors_invested[msg.sender] / invested_total * (uint(address(this).balance) - balance_busy);
    if (gain > uint(address(this).balance)-balance_busy) return; // do not let the investor deinvest in the case it is busy
    msg.sender.send(gain);
    investors_invested[msg.sender] = 0;
    for (k=0; k<investors_list_length; k++){
      if (investors_list[k] == msg.sender) investors_list[k] = 0x0;
    }
  }
  
  // get the current user insured amount
  function get() returns (uint){
    return users_balance[msg.sender];
  }

  // get a specific user insured amount
  function get_user(address user) returns (uint){
    return users_balance[user];
  }

  // returns percentage performance data about this investment
  function investment_ratio() returns (uint){
    uint insured_customers_funds = 0;
    for (uint k=0; k<users_list_length; k++){
      insured_customers_funds += users_balance[users_list[k]];
    }
    uint invested_total = 0;
    for (k=0; k<investors_list_length; k++){
      invested_total += investors_invested[investors_list[k]];
    }
    uint ratio = 100 * ((uint(address(this).balance) - insured_customers_funds)/invested_total);
    return ratio;
  }
}                                                                                                                             
