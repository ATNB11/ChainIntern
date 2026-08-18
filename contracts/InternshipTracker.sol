// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * InternshipTracker Smart Contract
 * Consensus: PoA (Proof of Authority) - Justification:
 * Campus-level permissioned environment where known, trusted nodes (university servers)
 * validate transactions. PoA is ideal because: (1) low energy consumption, (2) fast finality,
 * (3) no token economics needed, (4) Ganache simulates PoA by default.
 */
contract InternshipTracker {

    // ─── Roles ───────────────────────────────────────────────────────────────
    address public admin;

    mapping(address => bool) public isRecruiter;
    mapping(address => bool) public isStudent;
    mapping(address => string) public walletToName;

    // ─── Data Structures ─────────────────────────────────────────────────────
    struct Internship {
        uint256 id;
        address recruiterWallet;
        string companyName;
        string role;
        string description;
        string location;
        uint256 postedAt;
        bool isActive;
    }

    struct StatusEntry {
        string status;   // submitted | under_review | shortlisted | accepted | rejected
        uint256 timestamp;
        address updatedBy;
        string note;
    }

    struct Application {
        uint256 id;
        uint256 internshipId;
        address studentWallet;
        string studentName;
        uint256 submittedAt;
        StatusEntry[] statusHistory;  // append-only history
    }

    // ─── Storage ─────────────────────────────────────────────────────────────
    uint256 public internshipCount;
    uint256 public applicationCount;

    mapping(uint256 => Internship) public internships;
    mapping(uint256 => Application) public applications;

    // student => list of application IDs
    mapping(address => uint256[]) public studentApplications;
    // internship => list of application IDs
    mapping(uint256 => uint256[]) public internshipApplications;

    // ─── Events ──────────────────────────────────────────────────────────────
    event RecruiterRegistered(address indexed wallet, string name);
    event StudentRegistered(address indexed wallet, string name);
    event InternshipPosted(uint256 indexed id, address indexed recruiter, string role);
    event ApplicationSubmitted(uint256 indexed appId, uint256 indexed internshipId, address indexed student);
    event StatusUpdated(uint256 indexed appId, string newStatus, address indexed updatedBy);

    // ─── Modifiers ───────────────────────────────────────────────────────────
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyRecruiter() {
        require(isRecruiter[msg.sender], "Only recruiter");
        _;
    }

    modifier onlyStudent() {
        require(isStudent[msg.sender], "Only student");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // ─── Admin Functions ─────────────────────────────────────────────────────
    function registerRecruiter(address wallet, string memory name) external onlyAdmin {
        isRecruiter[wallet] = true;
        walletToName[wallet] = name;
        emit RecruiterRegistered(wallet, name);
    }

    function registerStudent(address wallet, string memory name) external onlyAdmin {
        isStudent[wallet] = true;
        walletToName[wallet] = name;
        emit StudentRegistered(wallet, name);
    }

    // ─── Recruiter Functions ──────────────────────────────────────────────────
    function postInternship(
        string memory role,
        string memory description,
        string memory location
    ) external onlyRecruiter returns (uint256) {
        internshipCount++;
        internships[internshipCount] = Internship({
            id: internshipCount,
            recruiterWallet: msg.sender,
            companyName: walletToName[msg.sender],
            role: role,
            description: description,
            location: location,
            postedAt: block.timestamp,
            isActive: true
        });
        emit InternshipPosted(internshipCount, msg.sender, role);
        return internshipCount;
    }

    function updateApplicationStatus(
        uint256 appId,
        string memory newStatus,
        string memory note
    ) external onlyRecruiter {
        Application storage app = applications[appId];
        require(app.id != 0, "App not found");
        uint256 internshipId = app.internshipId;
        require(internships[internshipId].recruiterWallet == msg.sender, "Not your internship");

        // Enforce forward-only transitions
        string memory current = app.statusHistory[app.statusHistory.length - 1].status;
        require(!_strEq(current, "accepted"), "Already accepted: terminal state");
        require(!_strEq(current, "rejected"), "Already rejected: terminal state");

        if (_strEq(current, "submitted")) {
            require(_strEq(newStatus, "under_review") || _strEq(newStatus, "rejected"),
                "From submitted: only under_review or rejected allowed");
        } else if (_strEq(current, "under_review")) {
            require(_strEq(newStatus, "shortlisted") || _strEq(newStatus, "rejected"),
                "From under_review: only shortlisted or rejected allowed");
        } else if (_strEq(current, "shortlisted")) {
            require(_strEq(newStatus, "accepted") || _strEq(newStatus, "rejected"),
                "From shortlisted: only accepted or rejected allowed");
        }

        app.statusHistory.push(StatusEntry({
            status: newStatus,
            timestamp: block.timestamp,
            updatedBy: msg.sender,
            note: note
        }));

        emit StatusUpdated(appId, newStatus, msg.sender);
    }

    function _strEq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    // ─── Student Functions ────────────────────────────────────────────────────
    function applyForInternship(uint256 internshipId) external onlyStudent returns (uint256) {
        require(internships[internshipId].isActive, "Internship not active");

        applicationCount++;
        Application storage app = applications[applicationCount];
        app.id = applicationCount;
        app.internshipId = internshipId;
        app.studentWallet = msg.sender;
        app.studentName = walletToName[msg.sender];
        app.submittedAt = block.timestamp;
        app.statusHistory.push(StatusEntry({
            status: "submitted",
            timestamp: block.timestamp,
            updatedBy: msg.sender,
            note: "Application submitted"
        }));

        studentApplications[msg.sender].push(applicationCount);
        internshipApplications[internshipId].push(applicationCount);

        emit ApplicationSubmitted(applicationCount, internshipId, msg.sender);
        return applicationCount;
    }

    // ─── View Functions ───────────────────────────────────────────────────────
    function getStatusHistory(uint256 appId) external view returns (StatusEntry[] memory) {
        return applications[appId].statusHistory;
    }

    function getStudentApplications(address student) external view returns (uint256[] memory) {
        return studentApplications[student];
    }

    function getInternshipApplications(uint256 internshipId) external view returns (uint256[] memory) {
        return internshipApplications[internshipId];
    }

    function getApplicationCount() external view returns (uint256) {
        return applicationCount;
    }

    function getInternshipCount() external view returns (uint256) {
        return internshipCount;
    }

    function getRole(address wallet) external view returns (string memory) {
        if (wallet == admin) return "admin";
        if (isRecruiter[wallet]) return "recruiter";
        if (isStudent[wallet]) return "student";
        return "unknown";
    }
}
