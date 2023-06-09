// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TicketsFactory.sol";

contract Tickets is ERC721, Ownable {
    event data(uint256 ticketCounter);

    struct TicketDataStruct {
        address owner;
        uint256 ticketNumber;
        string usedDate; //date when ticket was used
        bool setUsedAdmin; //this ticket have been set used by the admin
    }

    //ADMIN
    address public adminAddr; //validate userTickets entrance to event
    address public factoryContractAddr;

    //TICKET EVENT DATA
    string public eventDescription;
    string public eventName;
    string public eventDate;

    //BUISNESS LOGIC
    uint256 public ticketCounter;
    uint256 public ticketPrice;
    uint256 public maxTickets;
    uint256 public amountTickets;
    mapping(address => uint256[]) public userTickets;
    mapping(uint256 => TicketDataStruct) public ticketData;

    constructor(
        address _sender,
        string memory _name,
        string memory _description,
        uint256 _ticketPrice,
        uint256 _maxTickets,
        string memory _eventDate
    ) ERC721(_name, "TIX") {
        factoryContractAddr = msg.sender;
        _transferOwnership(_sender);
        adminAddr = _sender;
        eventName = _name;
        eventDescription = _description;
        eventDate = _eventDate;
        maxTickets = _maxTickets;
        ticketPrice = _ticketPrice * 1000000; //convert tfuel to drop
    }

    function getUserTickets(address _userAddress)
        public
        view
        returns (uint256[] memory)
    {
        return userTickets[_userAddress];
    }

    function getData()
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            eventName,
            eventDescription,
            eventDate,
            ticketCounter,
            ticketPrice,
            maxTickets
        );
    }

    function updateEventData(
        string memory _name,
        string memory _description,
        string memory _eventDate,
        uint256 _maxTickets,
        uint256 _ticketPrice
    ) public {
        eventName = _name;
        eventDescription = _description;
        eventDate = _eventDate;
        maxTickets = _maxTickets;
        ticketPrice = _ticketPrice * 1000000; //convert tfuel to drop
    }

    function setAdmin(address _newAdmin) public onlyOwner {
        adminAddr = _newAdmin;
    }

    function buyTicket() public payable {
        //requirements
        require(msg.value >= ticketPrice, "Insuficcient amount");
        require(ticketCounter < maxTickets, "Tickets sold");
        //increase ticket countment
        ticketCounter = ticketCounter + 1;
        //store ticket data
        userTickets[msg.sender].push(ticketCounter);
        ticketData[ticketCounter] = TicketDataStruct(
            msg.sender,
            ticketCounter,
            "not used yet",
            false
        );
        //emit nft
        _safeMint(msg.sender, ticketCounter);
        //emit new ticket count
        emit data(ticketCounter);
        //increase amount
        // amountTickets += msg.value;
        uint256 organizationFees = (2 * msg.value) / 100;
        //recaude fees
        ticketsFactory factoryContract = ticketsFactory(factoryContractAddr);
        factoryContract.recaudeFees{value: organizationFees}();
        amountTickets += msg.value - organizationFees;
    }

    //only admins
    function setTicketUsed(uint256 ticketNumber, string memory _usedDate)
        public
    {
        require(msg.sender == adminAddr);
        TicketDataStruct storage _ticket = ticketData[ticketNumber];
        require(_ticket.setUsedAdmin == false, "ticket has already been used");
        _ticket.setUsedAdmin = true;
        _ticket.usedDate = _usedDate;
    }

    //only creator
    function withdrawAmount(address payable) public onlyOwner{
        address owner = owner();
        payable(owner).transfer(amountTickets);
        amountTickets = 0;
    }
}