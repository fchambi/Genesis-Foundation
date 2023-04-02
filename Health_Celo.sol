// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MedicalRecords {
    
    address public admin;
    struct Doctor {
        address doctorAddress;
        string name;
        bool isRegistered;
        bool isApproved;
    }

    struct Lab {
        address labAddress;
        string name;
        bool isRegistered;
        bool isApproved;
    }

    struct MedicalRecord {
        string testName;
        string description;
        address patientAddress;
        address labAddress;
        uint256 timestamp; 
    }
    mapping(address => mapping(address => bool)) public labPermissions;
    mapping(address => mapping(uint256 => mapping(address => bool))) public sharedRecords;
    mapping(address => bool) public patients;
    mapping(address => Doctor) public doctors;
    mapping(address => Lab) public labs;
    mapping(address => mapping(uint256 => MedicalRecord)) public medicalRecords;
    mapping(address => uint256[]) public patientRecordIds;

    event PatientRegistered(address indexed patientAddress);
    event DoctorRegistered(address indexed doctorAddress, string name);
    event LabRegistered(address indexed labAddress, string name);
    event MedicalRecordAdded(address indexed patientAddress, uint256 indexed recordId, string testName, address labAddress);
    event MedicalRecordShared(address indexed patientAddress, uint256 indexed recordId, address withAddress);
  

    constructor() {
        admin = msg.sender;
    }
modifier onlyAdmin() {
    require(msg.sender == admin, "Just the Administrator ");
    _;
}

    function registerDoctor(string memory _name) public {
        require(!doctors[msg.sender].isRegistered, "Registered"); 
        doctors[msg.sender] = Doctor({
        doctorAddress: msg.sender,
        name: _name,
        isRegistered: true,
        isApproved:false
    });
    // Emits an event to indicate that a new doctor has been registered
    emit DoctorRegistered(msg.sender, _name);
    }

    function registerLab(string memory _name) public {
        require(!labs[msg.sender].isRegistered, "Its already Registered");   
        labs[msg.sender] = Lab({
        labAddress: msg.sender,
        name: _name,
        isRegistered: true,
        isApproved:false
    });
    // Emits an event to indicate that a new lab has been registered
    emit LabRegistered(msg.sender, _name);
    }
// This function is used to approve a doctor by the admin.
function approveDoctor(address doctorAddress) public onlyAdmin {
    // Check if the doctor is registered.
    require(doctors[doctorAddress].isRegistered, "Registered");
    // Check if the doctor is not already approved.
    require(!doctors[doctorAddress].isApproved, "No Approved");
    // Set the doctor's approval status to true.
    doctors[doctorAddress].isApproved = true;
}

// This function is used to reject a doctor by the admin.
function rejectDoctor(address doctorAddress) public onlyAdmin {
    // Check if the doctor is registered.
    require(doctors[doctorAddress].isRegistered, "Registered");
    // Check if the doctor is approved.
    require(doctors[doctorAddress].isApproved, "");
    // Set the doctor's approval status to false.
    doctors[doctorAddress].isApproved = false;
}

// This function is used to approve a lab by the admin.
function approveLab(address labAddress) public onlyAdmin {
    // Check if the lab is registered.
    require(labs[labAddress].isRegistered, "Registered");
    // Check if the lab is not already approved.
    require(!labs[labAddress].isApproved, "");
    // Set the lab's approval status to true.
    labs[labAddress].isApproved = true;
}

// This function is used to reject a lab by the admin.
function rejectLab(address labAddress) public onlyAdmin {
    // Check if the lab is registered.
    require(labs[labAddress].isRegistered, "Registered");
    // Check if the lab is approved.
    require(labs[labAddress].isApproved, "");
    // Set the lab's approval status to false.
    labs[labAddress].isApproved = false;
}

    // Function to register a patient
function registerPatient() public  {
    // Check if the patient is already registered using the sender's address
    require(!patients[msg.sender], "Patient already registered.");
    // Register the patient using the sender's address
    patients[msg.sender] = true;
    // Emits an event to indicate that a new patient has been registered
    emit PatientRegistered(msg.sender);
}
// Function to add a medical 
function addMedicalRecord(address _patientAddress, uint256 _recordId, string memory _testName, string memory _description) public {
        require(patients[_patientAddress], "Patient not registered.");
        require(labs[msg.sender].isApproved, "Lab not registered or not approved.");
        require(labPermissions[_patientAddress][msg.sender], "Lab does not have permission to add records for this patient.");

        MedicalRecord storage record = medicalRecords[_patientAddress][_recordId];
        require(record.timestamp == 0, "Record already exists.");

        record.testName = _testName;
        record.description = _description;
        record.patientAddress = _patientAddress;
        record.labAddress = msg.sender;
        record.timestamp = block.timestamp;

        patientRecordIds[_patientAddress].push(_recordId);

        emit MedicalRecordAdded(_patientAddress, _recordId, _testName, msg.sender);
    }
// Function to share a medical record
function shareMedicalRecord(uint256 _recordId, address _withAddress) public {
        require(patients[msg.sender], "Patient not registered.");
        require(doctors[_withAddress].isApproved || labs[_withAddress].isApproved, "Doctor or lab not registered.");

        MedicalRecord storage record = medicalRecords[msg.sender][_recordId];
        require(record.timestamp != 0, "Record does not exist.");
        require(!sharedRecords[msg.sender][_recordId][_withAddress], "Record already shared with this address.");

        sharedRecords[msg.sender][_recordId][_withAddress] = true;

        emit MedicalRecordShared(msg.sender, _recordId, _withAddress);
    }
// Function to get a medical record
function getMedicalRecord(address _patientAddress, uint256 _recordId) public view returns (MedicalRecord memory) {
        require(patients[_patientAddress], "Patient not registered.");
        require(doctors[msg.sender].isApproved || labs[msg.sender].isApproved, "Doctor or lab not registered.");
        // Verify if the medical record has been shared with the requesting physician or laboratory
        require(sharedRecords[_patientAddress][_recordId][msg.sender], "Record not shared with this address.");

        MedicalRecord storage record = medicalRecords[_patientAddress][_recordId];
        require(record.timestamp != 0, "Record does not exist.");

        return record;
    }
     event MedicalRecordAccessRevoked(address indexed patientAddress, uint256 indexed recordId, address withAddress);
// Function to revoke access to a previously shared medical record
function revokeAccessToMedicalRecord(uint256 _recordId, address _withAddress) public {
        require(patients[msg.sender], "Patient not registered.");
        require(sharedRecords[msg.sender][_recordId][_withAddress], "Record was not shared with this address.");

        sharedRecords[msg.sender][_recordId][_withAddress] = false;
// Emit an event to indicate that access to a medical record has been revoked
        emit MedicalRecordAccessRevoked(msg.sender, _recordId, _withAddress);
    }
     function grantLabPermission(address _labAddress) public {
        require(patients[msg.sender], "Patient not registered.");
        require(labs[_labAddress].isApproved, "Lab not registered or not approved.");

        labPermissions[msg.sender][_labAddress] = true;
    }
    // Function to revoke permission for a lab to add medical records
    function revokeLabPermission(address _labAddress) public {
        require(patients[msg.sender], "Patient not registered.");
        require(labPermissions[msg.sender][_labAddress], "Lab does not have permission.");

        labPermissions[msg.sender][_labAddress] = false;
    }
    function getAllPatientRecords(address _patientAddress) public view returns (MedicalRecord[] memory) {
    require(patients[_patientAddress], "Patient not registered.");
    require(_patientAddress == msg.sender || doctors[msg.sender].isApproved, "Access not allowed.");

    uint256[] storage recordIds = patientRecordIds[_patientAddress];
    MedicalRecord[] memory records = new MedicalRecord[](recordIds.length);

    for (uint256 i = 0; i < recordIds.length; i++) {
        records[i] = medicalRecords[_patientAddress][recordIds[i]];
    }

    return records;
}
}