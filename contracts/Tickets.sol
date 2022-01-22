//// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract Tickets {
    address payable admin;

    //The "Tkt", and "Evt" keywords are used as synonyms for for "Ticket" and "Event" respectively
    struct EventDetails {
        uint256 Evt_ID; // Generated Event ID
        address Evt_Mgr; // Event Manager
        uint256 Evt_Tkt_Price; // Ticket floor price
        uint256 Evt_Tkt_Count; // How many tickets this particular event has
        uint256 Evt_Start_Date; // EPOCH Date
        uint256 Evt_End_Date; // EPOCH Date
        bool Evt_Approved; // Whether if the event has been approved by the admin or not
        bool Evt_Tkt_Sale_Ready; // Whether if the event tickets is available for sale right now or not
    }

    struct TicketDetails {
        uint256 Tkt_ID; // Generated Ticket ID
        uint256 Evt_ID; // Linked Event ID
    }
}
