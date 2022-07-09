pragma solidity 0.7.5;
pragma abicoder v2;

contract MultiSigWallet {
    // Only owners can create transfer requests and approve them.
    // Number of approvals needed is set in the constructor.

    address[] public owners;
    uint limit;

    struct Transfer {
        uint amount;
        address payable recipient;
        uint approvals;
        bool hasBeenSent;
        uint id;
    }

    event TransferRequestCreated(uint _id, uint _amount, address _initiator, address _receiver);
    event ApprovalsReceived(uint _id, uint _approvals, address approver);
    event TransferApproved(uint _id);


    Transfer[] transferRequests;

    mapping(address => mapping(uint => bool)) approvals;

    // Should only allow owners to continue execution
    modifier OnlyOwners() {
        bool owner = false;
        for(uint i=0; i<owners.length; i++) {
            if(owners[i] == msg.sender) {
                owner = true;
            }
        }
        require(owner == true);
        _;
    }

    constructor(address[] memory _owners, uint _limit) {
        limit = _limit;
        owners = _owners;
    }

    function deposit() public payable {}

    function createTransfer(uint _amount, address payable _receiver) public OnlyOwners {
        emit TransferRequestCreated(transferRequests.length, _amount, msg.sender, _receiver);
        transferRequests.push(Transfer(_amount, _receiver, 0, false, transferRequests.length));
    }

    function approve(uint _id) public OnlyOwners {
        // Approve only once for unsent transactions.
        require(approvals[msg.sender][_id] == false);
        require(transferRequests[_id].hasBeenSent == false);

        approvals[msg.sender][_id] = true;
        transferRequests[_id].approvals++;
        emit ApprovalsReceived(_id, transferRequests[_id].approvals, msg.sender);

        // Do transfer if approval limit is reached.
        if(transferRequests[_id].approvals >= limit) {
            transferRequests[_id].hasBeenSent = true;
            transferRequests[_id].recipient.transfer(transferRequests[_id].amount);
            emit TransferApproved(_id);
        }

    }

    function getTransferRequests() public view returns (Transfer[] memory){
        return transferRequests;
    }
}
