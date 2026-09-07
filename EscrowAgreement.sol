// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LogisticsEscrow {
    // =============================================
    // 1. ENUMS (Lab 7, Page 3-6)
    // =============================================
    enum Stage {Init, Reg, Funded, InProgress, Completed, Refunded}
    Stage public stage;  // Track current stage like Lab 7 Exercise 1

    // =============================================
    // 2. STRUCTS (Lab 5, Page 29-30 | Lab 6, Page 3-5)
    // =============================================
    struct Milestone {
        string text;              // Description of milestone
        bool completed;           // Is it done?
        uint percentage;          // Release percentage (e.g., 30 for 30%)
        string proofHash;         // Verification proof
        uint completedTimestamp;  // When it was completed
    }

    struct Agreement {
        address shipper;          // Creator (buyer)
        address carrier;          // Service provider
        uint totalValue;          // Total ETH in wei
        uint deadline;            // Delivery deadline
        uint fundsReleased;       // How much has been released
        uint amountPaid;          // Total paid to carrier
        uint startTime;           // When agreement was created
        Stage state;              // Current stage
        Milestone[] milestones;   // Array of milestones (Lab 5, Page 29-30)
    }

    // =============================================
    // 3. STATE VARIABLES (Lab 5, Page 14)
    // =============================================
    uint public agreementCount;   // Track number of agreements
    mapping(uint => Agreement) public agreements;  // Lab 6, Page 10-13
    mapping(address => uint[]) public shipperAgreements;  // Track by user
    mapping(address => uint[]) public carrierAgreements;
    
    // User registration (Lab 6, Page 6-9 for address usage)
    mapping(address => bool) public registeredUsers;
    mapping(address => string) public userRoles;

    // =============================================
    // 4. EVENTS (Lab 6, Page 15 - Coin.sol example)
    // =============================================
    event AgreementCreated(uint indexed agreementId, address indexed shipper, address indexed carrier);
    event AgreementFunded(uint indexed agreementId, address indexed shipper, uint amount);
    event MilestoneVerified(uint indexed agreementId, uint milestoneIndex);
    event PaymentReleased(uint indexed agreementId, address indexed carrier, uint amount);
    event RefundProcessed(uint indexed agreementId, address indexed shipper, uint amount);

    // =============================================
    // 5. MODIFIERS (Lab 7, Page 18-25)
    // =============================================
    modifier onlyShipper(uint _agreementId) {
        require(msg.sender == agreements[_agreementId].shipper, "Only shipper can call");
        _;
    }

    modifier onlyCarrier(uint _agreementId) {
        require(msg.sender == agreements[_agreementId].carrier, "Only carrier can call");
        _;
    }

    modifier agreementExists(uint _agreementId) {
        require(_agreementId < agreementCount, "Agreement does not exist");
        _;
    }

    modifier validStage(Stage requiredStage) {
        require(stage == requiredStage, "Invalid stage for this action");
        _;
    }

    // Custom modifier like Lab 7 Exercise 4 (Page 22-25)
    modifier onlyRegistered() {
        require(registeredUsers[msg.sender], "User not registered");
        _;
    }

    // =============================================
    // 6. CONSTRUCTOR (Lab 3, Page 11-12)
    // =============================================
    constructor() {
        stage = Stage.Init;
        agreementCount = 0;
    }

    // =============================================
    // 7. USER REGISTRATION (Like Lab 6, Page 6-9)
    // =============================================
    function registerUser(string memory _role) public {
        require(!registeredUsers[msg.sender], "User already registered");
        
        // Check role like Lab 7 Ballot.sol (Page 8)
        require(
            keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("Shipper")) ||
            keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("Carrier")),
            "Must be Shipper or Carrier"
        );
        
        registeredUsers[msg.sender] = true;
        userRoles[msg.sender] = _role;
        
        emit AgreementCreated(0, msg.sender, msg.sender); // Use event for logging
    }

    // =============================================
    // 8. CREATE AGREEMENT (Lab 5, Page 20-21 function structure)
    // =============================================
    function createAgreement(
        address _carrier,
        uint _totalValue,
        uint _deadline,
        Milestone[] memory _milestones
    ) public onlyRegistered {
        // Validation
        require(registeredUsers[_carrier], "Carrier must be registered");
        require(msg.sender != _carrier, "Cannot be your own carrier");
        require(_milestones.length > 0, "Need at least one milestone");
        require(_deadline > block.timestamp, "Deadline must be in future");
        
        // Sum percentages like Lab 7 Ballot.sol (Page 8)
        uint totalPct = 0;
        for (uint i = 0; i < _milestones.length; i++) {
            totalPct += _milestones[i].percentage;
        }
        require(totalPct == 100, "Milestones must sum to 100%");
        
        uint agreementId = agreementCount;
        
        // Create agreement (struct pattern from Lab 6, Page 4-5)
        Agreement storage newAgreement = agreements[agreementId];
        newAgreement.shipper = msg.sender;
        newAgreement.carrier = _carrier;
        newAgreement.totalValue = _totalValue;
        newAgreement.deadline = _deadline;
        newAgreement.fundsReleased = 0;
        newAgreement.amountPaid = 0;
        newAgreement.startTime = block.timestamp;  // Lab 7, Page 15
        newAgreement.state = Stage.Init;
        
        // Push milestones to array (Lab 6, Page 4 - push method)
        for (uint i = 0; i < _milestones.length; i++) {
            newAgreement.milestones.push(_milestones[i]);
        }
        
        // Track agreements (Lab 5 mapping exercise)
        shipperAgreements[msg.sender].push(agreementId);
        carrierAgreements[_carrier].push(agreementId);
        
        agreementCount++;
        
        emit AgreementCreated(agreementId, msg.sender, _carrier);
    }

    // =============================================
    // 9. FUND ESCROW (Lab 6, Page 16-20 - Send Ether)
    // =============================================
    function fundEscrow(uint _agreementId) 
        public 
        payable 
        onlyRegistered 
        agreementExists(_agreementId)
        onlyShipper(_agreementId)
    {
        Agreement storage agreement = agreements[_agreementId];
        
        require(agreement.state == Stage.Init, "Already funded");
        require(msg.value == agreement.totalValue, "Send exact amount");
        require(msg.value > 0, "Must send some Ether");
        
        agreement.state = Stage.Funded;
        
        emit AgreementFunded(_agreementId, msg.sender, msg.value);
    }

    // =============================================
    // 10. VERIFY MILESTONE (Lab 5, Page 20-21)
    // =============================================
    function verifyMilestone(
        uint _agreementId,
        uint _milestoneIndex,
        string memory _proofHash
    ) 
        public 
        onlyRegistered
        agreementExists(_agreementId)
        onlyCarrier(_agreementId)
    {
        Agreement storage agreement = agreements[_agreementId];
        
        require(agreement.state == Stage.Funded || agreement.state == Stage.InProgress, 
                "Not in progress");
        require(_milestoneIndex < agreement.milestones.length, "Invalid milestone");
        require(block.timestamp <= agreement.deadline, "Deadline passed");
        
        Milestone storage milestone = agreement.milestones[_milestoneIndex];
        require(!milestone.completed, "Already completed");
        
        // Mark as completed
        milestone.completed = true;
        milestone.proofHash = _proofHash;
        milestone.completedTimestamp = block.timestamp;
        
        // Calculate payment (Lab 5 arithmetic)
        uint payment = (agreement.totalValue * milestone.percentage) / 100;
        
        // Send Ether using call method (Lab 6, Page 19-20 - recommended method)
        (bool sent, ) = payable(agreement.carrier).call{value: payment}("");
        require(sent, "Failed to send Ether");
        
        agreement.fundsReleased += payment;
        agreement.amountPaid += payment;
        
        // Check if all milestones done
        bool allDone = true;
        for (uint i = 0; i < agreement.milestones.length; i++) {
            if (!agreement.milestones[i].completed) {
                allDone = false;
                break;
            }
        }
        
        if (allDone) {
            agreement.state = Stage.Completed;
        } else {
            agreement.state = Stage.InProgress;
        }
        
        emit MilestoneVerified(_agreementId, _milestoneIndex);
        emit PaymentReleased(_agreementId, agreement.carrier, payment);
    }

    // =============================================
    // 11. REQUEST REFUND (Lab 7, Page 10-13 - Time units)
    // =============================================
    function requestRefund(uint _agreementId)
        public
        onlyRegistered
        agreementExists(_agreementId)
        onlyShipper(_agreementId)
    {
        Agreement storage agreement = agreements[_agreementId];
        
        // require(block.timestamp > agreement.deadline, "Deadline not passed");
        require(agreement.state != Stage.Completed, "Already completed");
        require(agreement.state != Stage.Refunded, "Already refunded");
        require(agreement.state == Stage.Funded || agreement.state == Stage.InProgress, 
                "Not refundable");
        
        // Send Ether using call method (Lab 6, Page 19-20)
        uint refundAmount = address(this).balance;
        (bool sent, ) = payable(agreement.shipper).call{value: refundAmount}("");
        require(sent, "Failed to send refund");
        
        agreement.state = Stage.Refunded;
        
        emit RefundProcessed(_agreementId, agreement.shipper, refundAmount);
    }

    // =============================================
    // 12. VIEW/GETTER FUNCTIONS (Lab 3, Page 17 - public variables)
    // =============================================
    function getAgreementSummary(uint _agreementId) 
        public 
        view 
        agreementExists(_agreementId) 
        returns (
            address shipper,
            address carrier,
            uint totalValue,
            uint released,
            uint paid,
            uint deadline,
            uint startTime,
            Stage state,
            uint milestoneCount,
            uint completedCount
        ) 
    {
        Agreement storage agreement = agreements[_agreementId];
        
        shipper = agreement.shipper;
        carrier = agreement.carrier;
        totalValue = agreement.totalValue;
        released = agreement.fundsReleased;
        paid = agreement.amountPaid;
        deadline = agreement.deadline;
        startTime = agreement.startTime;
        state = agreement.state;
        milestoneCount = agreement.milestones.length;
        
        // Count completed milestones
        completedCount = 0;
        for (uint i = 0; i < agreement.milestones.length; i++) {
            if (agreement.milestones[i].completed) {
                completedCount++;
            }
        }
    }
    
    // Get milestones array (Lab 6, Page 4)
    function getMilestones(uint _agreementId) 
        public 
        view 
        agreementExists(_agreementId) 
        returns (Milestone[] memory) 
    {
        return agreements[_agreementId].milestones;
    }
    
    // Get all agreements for a user (mapping pattern from Lab 6)
    function getShipperAgreements(address _shipper) 
        public 
        view 
        returns (uint[] memory) 
    {
        return shipperAgreements[_shipper];
    }
    
    function getCarrierAgreements(address _carrier) 
        public 
        view 
        returns (uint[] memory) 
    {
        return carrierAgreements[_carrier];
    }
    
    // Get contract balance (Lab 6, Page 7)
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    // Check if milestone completed (Lab 5, Page 20-21)
    function isMilestoneCompleted(uint _agreementId, uint _milestoneIndex) 
        public 
        view 
        agreementExists(_agreementId) 
        returns (bool) 
    {
        require(_milestoneIndex < agreements[_agreementId].milestones.length, "Invalid");
        return agreements[_agreementId].milestones[_milestoneIndex].completed;
    }

    function getCurrentTime() public view returns (uint) {
    return block.timestamp;
    }
}
