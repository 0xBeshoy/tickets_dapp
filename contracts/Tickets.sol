// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Tickets is Ownable {
    address payable admin;
    uint256 internal NONCE;
    address payable public WALLET;

    //The "Tkt", and "Evt" keywords are used as synonyms for for "Ticket" and "Event" respectively
    struct EventDetails {
        uint256 Evt_ID; // Generated Event ID
        address Evt_Mgr; // Event Manager
        uint256 Evt_Tkt_Price; // Ticket floor price
        uint256 Evt_Tkt_Allowed_Count; // How many tickets this particular event can have
        uint256 Evt_Start_Date; // EPOCH Date
        uint256 Evt_End_Date; // EPOCH Date
        bool Evt_Approved; // Whether if the event has been approved by the admin or not
        bool Evt_Tkt_Sale_Ready; // Whether if the event tickets is available for sale right now or not
        TicketDetails[] Evt_Tickets; // The Event tickets struct array which will contain every ticket purchased for that specific event
    }

    struct TicketDetails {
        uint256 Tkt_ID; // Generated Ticket ID
        uint256 Evt_ID; // Linked Event ID
        address Tkt_Owner; // Owner of this specific ticket
        uint256 Tkt_Price; // Purchased ticket price
        uint256 Tkt_Purchase_Date; //EPOCH date of ticket purchase date
        uint256 Evt_Start_Date; // EPOCH Date
        uint256 Evt_End_Date; // EPOCH Date
    }

    address[] public allEventManagers; // All event managers in the contract
    address[] public allTicketBuyers; // All buyers of all tickets in the contract
    address[] public allEventTicketBuyers; // All buyers of tickets in specific event
    uint256[] public allEvents; // All event IDs in one array;
    // uint256[][] public allTickets; // All ticket IDs in one array
    EventDetails[] public allEventStructs; // All event structs in one array

    mapping(uint256 => EventDetails) public eventsDB; // All events
    mapping(uint256 => uint256[]) public eventTickets; // All tickets in a specific event (<eventID> => ticketsArray[])
    mapping(uint256 => mapping(uint256 => address)) public ownerOfTicket; // An owner of a specific ticket in specific event (<eventID> => (<ticketID> => address))
    mapping(uint256 => mapping(uint256 => TicketDetails)) public ticketDetails; // Full details of any given ticketID in an event.
    mapping(uint256 => mapping(address => uint256))
        private balanceOfEthPerOwner; // All eth paid by a specific owner in a specific event. Should default to ZERO per event after event is disabled or ended TODO: this is a bug which may allow balance to be either wiped out or be easily stolen
    mapping(uint256 => mapping(address => uint256)) balanceOfTickets; // Tickets amount per address per event <eventID => (buyerAddress => balance)> // could we use ticketsOfAddress[eventID][address][balance].length?
    mapping(uint256 => mapping(address => uint256[])) public ticketsOfAddress; // All tickets owned by an address per event (<eventID> => (buyerAddress => ticketsOwnedArray[]))
    mapping(address => uint256[]) public eventsPerAddress; // All events attended by specific address (<address> => eventsArray[])
    mapping(uint256 => address) public managerOfEvent;
    mapping(address => uint256[]) public eventsPerManager; // All events per manager address

    // Modifiers
    modifier isEventManager(uint256 eventID_) {
        require(
            eventsDB[eventID_].Evt_Mgr == msg.sender,
            "Only Event Managers are allowed to do this action"
        );
        _;
    }

    // modifier isTicketBuyer{uint eventID_){
    //     require(

    //     );
    //     _;
    // }

    modifier isSaleReady(uint256 eventID_) {
        require(
            eventsDB[eventID_].Evt_Tkt_Sale_Ready == true,
            "Event ticket sales should be approved first"
        );
        _;
    }

    // Some utility functions

    constructor() payable {
        NONCE = uint256(
            keccak256(
                abi.encodePacked(
                    block.number,
                    block.difficulty,
                    block.timestamp,
                    msg.sender
                )
            )
        );
        WALLET = payable(this);
    }

    fallback() external payable {}

    receive() external payable {}

    /// @notice Returns a pseudo-random number
    /// @dev Will be used to generate EventID, TicketsID, etc.,
    function generateRandNum() public view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.number,
                    block.difficulty,
                    block.timestamp,
                    msg.sender,
                    NONCE
                )
            )
        );
        return (randomNumber % (1000000 - 100000)) + 100000;
    }

    function createEvent(
        uint256 price_,
        uint256 amount_,
        uint256 startDate_,
        uint256 endDate_
    ) public payable returns (uint256) {
        uint256 _eventID = generateRandNum();
        eventsDB[_eventID].Evt_ID = _eventID;
        eventsDB[_eventID].Evt_Mgr = msg.sender;
        eventsDB[_eventID].Evt_Tkt_Price = price_;
        eventsDB[_eventID].Evt_Tkt_Allowed_Count = amount_;
        eventsDB[_eventID].Evt_Start_Date = startDate_;
        eventsDB[_eventID].Evt_End_Date = endDate_;
        eventsDB[_eventID].Evt_Approved = false;
        eventsDB[_eventID].Evt_Tkt_Sale_Ready = false;

        allEvents.push(_eventID);
        return _eventID;
    }

    /// @notice Allows the Contract admin to approve the Event
    /// @dev onlyOwner modifier should be invoked
    /// @param eventID_ EventID returned from the createEvent() function
    /// @return bool true/false if the approval was successful of not
    function approveEvent(uint256 eventID_) public onlyOwner returns (bool) {
        require(eventsDB[eventID_].Evt_ID > 0, "Event Not Found");
        require(
            eventsDB[eventID_].Evt_Approved == false,
            "Event already approved before"
        );
        eventsDB[eventID_].Evt_Approved = true;

        return true;
    }

    /// @notice Allows the event manager to approve the selling of the event tickets
    /// @dev isEventManager modifier should be invoked
    /// @param eventID_ EventID returned from the createEvent() function
    /// @return bool true/false if the approval was successful of not
    function allowSale(uint256 eventID_)
        public
        isEventManager(eventID_)
        returns (bool)
    {
        require(eventsDB[eventID_].Evt_ID > 0, "Event Not Found");
        require(
            eventsDB[eventID_].Evt_Approved == true,
            "Event should be approved first by the contract admin"
        );
        require(
            eventsDB[eventID_].Evt_Tkt_Sale_Ready == false,
            "Event ticket sales already approved by an event manager"
        );

        require(
            eventsDB[eventID_].Evt_End_Date > block.timestamp,
            "Event has already been ended"
        );

        eventsDB[eventID_].Evt_Tkt_Sale_Ready = true;

        return true;
    }

    function disableEvent(uint256 eventID_) public onlyOwner returns (bool) {
        require(
            eventsDB[eventID_].Evt_Approved == true &&
                eventsDB[eventID_].Evt_End_Date > block.timestamp,
            "Event isn't approved already and/or the event has already been ended"
        );

        eventsDB[eventID_].Evt_Approved = false;

        return true;
    }

    function buyTickets(uint256 eventID_, uint256 amount_)
        public
        payable
        isSaleReady(eventID_)
    {
        require(
            eventsDB[eventID_].Evt_End_Date > block.timestamp,
            "Event should be started first and/or shouldn't be ended too"
        );
        require(
            amount_ > 0 &&
                eventsDB[eventID_].Evt_Tkt_Allowed_Count >= // Number of max allowed tickets to be sold
                (eventTickets[eventID_].length + amount_), // Number of already purchased tickets
            "You must supply an amount of tickets that is less than the max allowed tickets to be ever sold"
        );
        uint256 totalPrice = eventsDB[eventID_].Evt_Tkt_Price * amount_;

        require(
            msg.sender.balance >= totalPrice,
            "Please transfer some ETHer to your wallet first"
        );
        require(msg.value >= totalPrice, "Insufficient amount of ETHer sent");

        for (uint256 i = 0; i < amount_; i++) {
            uint256 tk_id = eventsDB[eventID_].Evt_Tickets.length + 1;

            eventsDB[eventID_].Evt_Tickets.push(
                TicketDetails(
                    tk_id,
                    eventID_,
                    msg.sender,
                    (msg.value / amount_),
                    block.timestamp,
                    eventsDB[eventID_].Evt_Start_Date,
                    eventsDB[eventID_].Evt_End_Date
                )
            );

            eventTickets[eventID_].push(tk_id);
            ownerOfTicket[eventID_][tk_id] = msg.sender;
            ticketDetails[eventID_][tk_id] = TicketDetails(
                tk_id,
                eventID_,
                msg.sender,
                (msg.value / amount_),
                block.timestamp,
                eventsDB[eventID_].Evt_Start_Date,
                eventsDB[eventID_].Evt_End_Date
            );
        }
        payable(WALLET).transfer(msg.value);
    }

    function getWalletBalance() public view returns (uint256) {
        return WALLET.balance;
    }

    function getEventTicketCount(uint256 eventID_)
        public
        view
        returns (uint256)
    {
        return eventTickets[eventID_].length;
    }

    function getTicketInfo(uint256 eventID_, uint256 ticketID_)
        public
        view
        returns (TicketDetails memory)
    {
        return ticketDetails[eventID_][ticketID_];
    }

    // function requestRefund() isAttendee {}

    // function refundAttendee() isEventManager {}

    // function refundAll() isEventManager {}

    // function setCommissionPercentage() onlyOwner {}

    // function withdrawCommissions() onlyOwner {}

    // function getTicketPrice() view returns () {}

    // function getRemainingTickets() view returns () {}

    // function getOrganizers() view returns () {}

    // function getAllOrganizers() view returns () {}

    // function getTicketCount() view returns () {}

    // function getAllEvents() view returns () {}
}
