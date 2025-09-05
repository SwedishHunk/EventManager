// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract EventManager {
    // ---- Reentrancy-guard ----
    uint256 private _locked = 1;
    modifier nonReentrant() {
        require(_locked == 1, "Reentrant call");
        _locked = 2;
        _;
        _locked = 1;
    }

    // ---- Datamodell ----
    struct EventData {
        address organizer;            // Skaparen/ansvarig
        string name;                  // Namn
        uint256 ticketPrice;          // Avgift i wei
        uint256 userLimit;            // Max antal deltagare
        uint256 deadline;             // Sista anmälningstid (unix timestamp)
        bool isOpen;                  // Ar anmälan öppen?
        uint256 sold;                 // Antal anmälda
        uint256 balance;              // Ackumulerade medel för just detta event
        address[] participants;       // Lista över deltagare
        mapping(address => bool) registered; // Snabbkoll: har adressen anmält sig?
    }

    address public owner;
    uint256 public nextEventId;                // Räknare för ID
    mapping(uint256 => EventData) private eventsById;

    
    // ---- Custom errors ----
    error EventNotFound();
    error InsufficientPayment();
    error AlreadyRegistered();
    error EventFull();
    error DeadlinePassed();
    error OnlyOwner();
    error OnlyOrganizer();
    error InvalidEventData();

    // ---- Events (loggar) ----
    event EventCreated(uint256 indexed eventId, address indexed organizer, string name);
    event RegistrationOpened(uint256 indexed eventId);
    event RegistrationClosed(uint256 indexed eventId);
    event Registered(uint256 indexed eventId, address indexed attendee, uint256 price);
    event Withdrawn(uint256 indexed eventId, address indexed organizer, uint256 amount);

    // ---- Custom modifiers ----
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }
    
    modifier onlyOrganizer(uint256 _eventId) {
        if (msg.sender != eventsById[_eventId].organizer) revert OnlyOrganizer();
        _;
    }

    // ---- Skapa nytt evenemang ----
    function createEvent(
        string calldata name_,
        uint256 ticketPrice_,
        uint256 userLimit_,
        uint256 deadline_   // absolut tid (block.timestamp-baserad)
    ) external returns (uint256 eventId) {
        require(bytes(name_).length > 0, "Name required");
        require(ticketPrice_ > 0, "ticketPrice must be > 0");
        require(userLimit_ > 0, "userLimit must be > 0");
        require(deadline_ > block.timestamp, "Deadline must be in the future");

        eventId = nextEventId++;
        EventData storage e = eventsById[eventId];
        e.organizer   = msg.sender;
        e.name        = name_;
        e.ticketPrice = ticketPrice_;
        e.userLimit   = userLimit_;
        e.deadline    = deadline_;
        e.isOpen      = false; // startar stängd tills man öppnar

        emit EventCreated(eventId, msg.sender, name_);
    }

    // ---- Öppna/Stäng anmälan ----
    function openRegistration(uint256 eventId) external {
        EventData storage e = _requireEventOrganizer(eventId);
        require(block.timestamp < e.deadline, "Deadline passed");
        require(!e.isOpen, "Already open");
        e.isOpen = true;
        emit RegistrationOpened(eventId);
    }

    function closeRegistration(uint256 eventId) external {
        EventData storage e = _requireEventOrganizer(eventId);
        require(e.isOpen, "Already closed");
        e.isOpen = false;
        emit RegistrationClosed(eventId);
    }

    // ---- Anmälan (betalning hanteras här) ----
    function register(uint256 eventId) external payable nonReentrant {
        EventData storage e = eventsById[eventId];
        require(e.organizer != address(0), "Event not found");
        require(e.isOpen, "Registration closed");
        require(block.timestamp < e.deadline, "Deadline passed");
        require(e.sold < e.userLimit, "Sold out");
        require(!e.registered[msg.sender], "Already registered");
        require(msg.value == e.ticketPrice, "Wrong price");

        // Spara deltagare
        e.registered[msg.sender] = true;
        e.participants.push(msg.sender);
        e.sold += 1;

        // Bokför evenemangets kassa
        e.balance += msg.value;

        // Auto-stang om vi nådde max
        if (e.sold == e.userLimit) {
            e.isOpen = false;
            emit RegistrationClosed(eventId);
        }

        emit Registered(eventId, msg.sender, msg.value);
    }

    // ---- Uttag av medel per evenemang ----
    // Tillåts när registrering inte är öppen OCH (deadline passerad eller fullsatt).
    function withdraw(uint256 eventId) external nonReentrant {
        EventData storage e = _requireEventOrganizer(eventId);
        require(!e.isOpen, "Close registration first");
        require(block.timestamp >= e.deadline || e.sold == e.userLimit, "Too early");

        uint256 amount = e.balance;
        require(amount > 0, "Nothing to withdraw");
        e.balance = 0;

        (bool ok, ) = payable(e.organizer).call{value: amount}("");
        require(ok, "Transfer failed");

        emit Withdrawn(eventId, e.organizer, amount);
    }

    // ---- Läsfunktioner ----
    function getEventInfo(uint256 eventId)
        external
        view
        returns (
            address organizer,
            string memory name,
            uint256 ticketPrice,
            uint256 userLimit,
            uint256 deadline,
            bool isOpen,
            uint256 sold,
            uint256 balance
        )
    {
        EventData storage e = eventsById[eventId];
        require(e.organizer != address(0), "Event not found");
        return (e.organizer, e.name, e.ticketPrice, e.userLimit, e.deadline, e.isOpen, e.sold, e.balance);
    }

    function getParticipants(uint256 eventId) external view returns (address[] memory) {
        EventData storage e = eventsById[eventId];
        require(e.organizer != address(0), "Event not found");
        return e.participants;
    }

    function isRegistered(uint256 eventId, address user) external view returns (bool) {
        EventData storage e = eventsById[eventId];
        require(e.organizer != address(0), "Event not found");
        return e.registered[user];
    }

    // ---- Hjälpare ----
    function _requireEventOrganizer(uint256 eventId) internal view returns (EventData storage e) {
        e = eventsById[eventId];
        require(e.organizer != address(0), "Event not found");
        require(msg.sender == e.organizer, "Not organizer");
    }

    // Förhindra oavsiktliga insättningar
    receive() external payable { revert("Send via register()"); }
    fallback() external payable { revert("Send via register()"); }
}
