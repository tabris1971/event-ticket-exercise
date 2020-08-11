pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;
    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string URL;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

  
    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier verifyOwner {require(owner == msg.sender);_;}

    constructor() public {
        owner = msg.sender;
    }
    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _description, string memory _URL, uint _totalTickets)
        public
        payable
        verifyOwner
        returns (uint)
    {   
        Event memory anEvent;
        anEvent.description =_description;
        anEvent.URL = _URL;
        anEvent.totalTickets = _totalTickets;
        anEvent.isOpen = true;
        events[idGenerator] = anEvent;
        idGenerator +=1;
        emit LogEventAdded(anEvent.description, anEvent.URL, anEvent.totalTickets, idGenerator-1);
        return(idGenerator-1);

    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint eventId) 
        public
        view
        returns(string memory description, string memory URL, uint totalTickets, uint sales, bool isOpen)
    {
        
        return (events[eventId].description, events[eventId].URL, events[eventId].totalTickets, events[eventId].sales, events[eventId].isOpen);
    }    
    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint eventId, uint numTickets) public payable  {
        uint price = numTickets * PRICE_TICKET;
        require (events[eventId].isOpen == true);
        require (msg.value >= price);
        require (events[eventId].totalTickets >= numTickets);
        events[eventId].buyers[msg.sender] += numTickets;
        events[eventId].sales += numTickets;
        events[eventId].totalTickets -= numTickets;
        uint refund = msg.value - price;
        msg.sender.transfer(refund);
        emit LogBuyTickets(msg.sender, eventId, numTickets);

    }
    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund (uint eventId) 
        public 
        payable 
    {
        uint refundTickets = events[eventId].buyers[msg.sender];
        require (refundTickets>0);
        events[eventId].sales -= refundTickets;
        events[eventId].totalTickets += refundTickets;
        uint refundAmount = refundTickets * PRICE_TICKET;
        msg.sender.transfer(refundAmount);
        emit LogGetRefund(msg.sender, eventId, refundTickets);
    }
    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint eventId) public view returns (uint) {
        return events[eventId].buyers[msg.sender];
    }
    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint eventId)
        public
        payable
        verifyOwner
    {
        events[eventId].isOpen = false;
        uint balance = events[eventId].sales * PRICE_TICKET;
        msg.sender.transfer(balance);
        emit LogEndSale(msg.sender, balance, eventId );
    }    
}
