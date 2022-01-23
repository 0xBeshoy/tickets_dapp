//// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Tickets is Ownable {
    address payable admin;

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
    }

    struct TicketDetails {
        uint256 Tkt_ID; // Generated Ticket ID
        uint256 Evt_ID; // Linked Event ID
        uint256 Tkt_Price; // Purchased ticket price
        uint256 Tkt_Purchase_Date; //EPOCH date of ticket purchase date
        uint256 Evt_Start_Date; // EPOCH Date
        uint256 Evt_End_Date; // EPOCH Date
    }

    address[] internal allEventManagers; // All event managers in the contract
    address[] internal allTicketBuyers; // All buyers of all tickets in the contract
    address[] public allEventTicketBuyers; // All buyers of tickets in specific event

    mapping(uint256 => EventDetails) public eventDB;
    mapping(uint256 => uint256) public eventTicketsDB;
    mapping(uint256 => address) public ownerOfTicket;
    mapping(uint256 => address) public managerOfEvent;
    mapping(uint256 => mapping(address => uint256)) balanceOfTickets; // Tickets amount per address per event <eventID => (buyerAddress => balance)>

    // Modifiers
    modifier isEventManager(uint256 _eventID) {
        require(
            eventDB[_eventID].Evt_Mgr == msg.sender,
            "Only Event Managers are allowed to do this action"
        );
        _;
    }

    // modifier isTicketBuyer{uint _eventID){
    //     require(

    //     );
    //     _;
    // }

    // function createEvent() isEventManager {}

    // function disableEvent() onlyOwner {}

    // function buyTickets() {}

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
