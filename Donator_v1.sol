pragma solidity ^0.8.0;

contract Donator {
    
    address private tokenAddress;
    int constant public maxEntries = 100000;

    uint256 public requestsCount = 0;
    mapping(uint256 => Request) public requests;
    uint256 public idsOfRequestsCount = 0;
    uint256 [maxEntries] idsOfRequests;

    uint256 public achievementsCount = 0;
    mapping(uint256 => Achievement) achievements;
    uint256 public idsOfAchievementsCount = 0;
    uint256 [maxEntries] idsOfAchievements;

    uint256 public donationsCount = 0;
    mapping(uint256 => Donation) public donations;
    uint256 public idsOfDonationsCount = 0;
    uint256 [maxEntries] idsOfDonations;

    struct Request {
        uint256 id;
        string hash;
        string title;
        string description;
        uint256 numDonations;
        uint256 totalDonationsAmount;
        uint256 outstandingDonations;
        uint256 acceptedDonations;
        address payable requestor;
    }

    struct Achievement {
        uint256 id;
        string hash;
        string title;
        string description;
        uint256 requestId;
        address payable requestor;
    }

    struct Donation {
        uint256 id;
        string description;
        uint256 amount;
        uint256 requestId;
        address payable donator;
    }
    
    receive() external payable {
            // React to receiving ether
        }

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function uploadRequest(
        string memory _hash,
        string memory _title,
        string memory _description
    ) public returns(uint256){
        require(bytes(_hash).length > 0);
        require(bytes(_description).length > 0);
        require(msg.sender != address(0));

        requestsCount++;

        // Set a spot in the mapping to a new Request
        requests[requestsCount] = Request(
            requestsCount,
            _hash,
            _title,
            _description,
            0,
            0,
            0,
            0,
            payable(msg.sender)
        );
        
        // Store the id
        idsOfRequests[idsOfRequestsCount] = requestsCount;
        idsOfRequestsCount++;
        return (idsOfRequests.length);
    }

    function uploadAchievement(
        uint256 _requestId,
        string memory _hash,
        string memory _title,
        string memory _description
    ) public payable {
        require(
            _requestId > 0, "Invalid _achievementId"
        );

        require(
            requests[_requestId].requestor == msg.sender,
            "Only the requestor may upload Achievements to their Request."
        );

        achievementsCount++;

        // Set a spot in the mapping to a new Achievement
        achievements[achievementsCount] = Achievement(
            donationsCount,
            _hash,
            _title,
            _description,
            _requestId,
            payable(msg.sender)
        );
        
        // Store the id
        idsOfAchievements[idsOfAchievementsCount] = achievementsCount;
        idsOfAchievementsCount++;
    }

    function donate(uint256 _requestId, string memory _description)
        public
        payable
    {
        require(
            _requestId > 0, "Invalid _requestId"
        );

        Request memory _request = requests[_requestId];

        // Pay the smart contract. Funds come from a donator.
        payable(this).transfer(msg.value);

        // Update the field on the Request
        _request.outstandingDonations += msg.value;
        _request.numDonations += 1;
        _request.totalDonationsAmount += msg.value;
        requests[_requestId] = _request;

        donationsCount++;

        // Set a spot in the mapping to a new Donation
        donations[donationsCount] = Donation(
            donationsCount,
            _description,
            msg.value,
            _requestId,
            payable(msg.sender)
        );
        
        // Store the id
        idsOfDonations[idsOfDonationsCount] = donationsCount;
        idsOfDonationsCount++;
    }

    function receiveDonation(uint256 _donationId) public payable {
        require(
            _donationId > 0, "Invalid _donationId"
        );

        Donation memory _donation = donations[_donationId];
        Request memory _request = requests[_donation.requestId];
        address payable _requestor = _request.requestor;

        // Ensure that the actor is the correct requestor
        require(
            msg.sender == _requestor,
            "Only the requestor may receive the Donations of their Request."
        );

        // Pay the receiver. Funds come from the smart contract.
        payable(_request.requestor).transfer(_donation.amount);

        // Update the fields on the Request
        _request.acceptedDonations += _donation.amount;
        _request.outstandingDonations -= _donation.amount;
        requests[_request.id] = _request;

        deleteDonation(_donationId);
    }
    
    function refundDonation(uint256 _donationId) public payable {
        require(
            _donationId > 0, "Invalid _donationId"
        );
        
        Donation memory _donation = donations[_donationId];
                Request memory _request = requests[
            _donation.requestId
        ];
        
        // Ensure that the actor is the correct donator
        require(
            msg.sender == _donation.donator,
            "Only the donator may refund their Donation."
        );
        
        // Pay back the donator. Funds come from the smart contract.
        payable(_donation.donator).transfer(_donation.amount);
        
        // Update the fields on the Request
        _request.outstandingDonations -= _donation.amount;
        _request.numDonations -= 1;
        requests[_request.id] = _request;
        
        deleteDonation(_donationId);
    }

    function deleteRequest(uint256 _requestId) private {
        // Delete id from array
        uint256 _index = getIndexOfRequestId(_requestId);
        idsOfRequests[_index] = idsOfRequests[idsOfRequests.length - 1];
        delete idsOfRequests[idsOfRequests.length - 1];
        idsOfRequestsCount--;
        
        requestsCount--;
        delete (requests[_requestId]);
    }

    function deleteAchievemnt(uint256 _achievementId) private {
        // Delete id from array
        uint256 _index = getIndexOfAchievementId(_achievementId);
        idsOfAchievements[_index] = idsOfAchievements[idsOfAchievements.length - 1];
        delete idsOfAchievements[idsOfAchievements.length - 1];
        idsOfAchievementsCount--;
        
        achievementsCount--;
        delete (achievements[_achievementId]);
    }

    function deleteDonation(uint256 _donationId) private {
        // Delete id from array
        uint256 _index = getIndexOfDonationId(_donationId);
        idsOfDonations[_index] = idsOfDonations[idsOfDonations.length - 1];
        delete idsOfDonations[idsOfDonations.length - 1];
        idsOfDonationsCount--;
        
        donationsCount--;
        delete (donations[_donationId]);
    }
    
        function getIndexOfRequestId(uint256 _id) private view returns(uint256 index) {
        for (uint256 i = 0; i < idsOfRequests.length; i++) {
            if (idsOfRequests[i] == _id) {
                return i;
            }
        }
    }
    
        function getIndexOfAchievementId(uint256 _id) private view returns(uint256 index) {
        for (uint256 i = 0; i < idsOfAchievements.length; i++) {
            if (idsOfAchievements[i] == _id) {
                return i;
            }
        }
    }
    
    function getIndexOfDonationId(uint256 _id) private view returns(uint256 index) {
        for (uint256 i = 0; i < idsOfDonations.length; i++) {
            if (idsOfDonations[i] == _id) {
                return i;
            }
        }
    }
}
