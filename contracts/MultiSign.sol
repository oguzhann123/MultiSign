// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract MultiSign {
    address[] public signers;
    uint256 public requiredConfirmations;

    modifier Requirements(uint256 _nonce) {
        require(_nonce < nonce, "Not exists");
        require(txConfirms[_nonce][msg.sender] == false, "Already approved.");
        require(
            nonceToTransaction[_nonce].deadline > block.timestamp,
            "Time out"
        );
        require(
            nonceToTransaction[_nonce].executed == false,
            "Already executed"
        );
        _;
    }  

    modifier onlySigners() {
        bool signer = false;
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == msg.sender) signer = true; // ??
        }
        require(signer, "Not Signer");
        _;
    }

    constructor(address[] memory _signers, uint256 _requiredConfirmations) {
        require(_signers.length > 0, "Any Signer.");
        require(isUnique(_signers), "Duplicate address.");
        require(_requiredConfirmations <= _signers.length, "Not enough signer");

        signers = _signers;
        requiredConfirmations = _requiredConfirmations;
    }
    receive() external payable { }
    fallback() external payable { }

    uint256 public nonce;

    mapping(uint256 => Transaction) public nonceToTransaction; // depolama icin
    mapping(uint256 => mapping(address => bool)) public txConfirms;

    event NewProposal(address proposer, uint256 id);
    event Executed(address executor, uint id, bool success);

    struct Transaction {
        address proposer; // kimin getirdigini ve kimin onerdigi
        uint256 confirmations; // kac kisi tarafindan onaylandigi
        bool executed; // gerceklestirip yada gerceklestirilmemesi
        uint256 deadline;
        address toAddress; //
        uint256 value; //    the last 3 variables 1 islemin gercelestirilmesi icin kritik unsurlar
        bytes txData; //
    }

    function isUnique(address[] memory arr) private pure returns (bool) {
        for (uint256 i = 0; i < arr.length - 1; i++) {
            for (uint256 j = i + 1; j < arr.length; j++) {
                require(arr[i] != arr[j], "Duplicate address");
            }
            return true;
        }
    }

    function proposeTx(
        uint256 _deadline,
        address _toAddress,
        uint256 _value,
        bytes memory _txData
    ) external onlySigners {
        require(_deadline > block.timestamp, "Time out");
        Transaction memory _tx = Transaction({
            proposer: msg.sender,
            confirmations: 0,
            executed: false,
            deadline: _deadline,
            toAddress: _toAddress,
            value: _value,
            txData: _txData
        });
        nonceToTransaction[nonce] = _tx;
        emit NewProposal(msg.sender, nonce);

        nonce++;
    } // 31=?14

    function confirmTx(uint256 _nonce)
        external
        onlySigners
        Requirements(_nonce)
    {
        // require(_nonce< nonce,"Not exists");
        // require(txConfirms[_nonce][msg.sender]==false,"Already approved.");
        // require(nonceToTransaction[_nonce].deadline>block.timestamp,"Time out");
        // require(nonceToTransaction[_nonce].executed== false,"Already executed");

        nonceToTransaction[_nonce].confirmations++;
        txConfirms[_nonce][msg.sender] = true;
    }

    function rejectTx(uint256 _nonce)
        external
        onlySigners
        Requirements(_nonce)
    {
        //    require(_nonce< nonce,"Not exists");
        //     require(txConfirms[_nonce][msg.sender]==false,"Already approved.");
        //     require(nonceToTransaction[_nonce].deadline>block.timestamp,"Time out");
        //     require(nonceToTransaction[_nonce].executed== false,"Already executed");
        nonceToTransaction[_nonce].confirmations--;
        txConfirms[_nonce][msg.sender] = false;
    }

    function deleteTx(uint256 _nonce) external onlySigners {
        require(_nonce < nonce, "Not exists");
        require(
            nonceToTransaction[_nonce].executed == false,
            "Already executed"
        );
        require(
            nonceToTransaction[_nonce].proposer == msg.sender,
            "Not transaction owner"
        );
        require(
            nonceToTransaction[_nonce].confirmations < requiredConfirmations,
            "Already confirmed"
        );

        nonceToTransaction[_nonce].executed = true;
    }

    function executedTx(uint256 _nonce) external onlySigners returns (bool) {
        require(_nonce < nonce, "Not exists");
        require(
            nonceToTransaction[_nonce].deadline > block.timestamp,
            "Time out"
        );
        require(
            nonceToTransaction[_nonce].confirmations >= requiredConfirmations,
            "Already confirmed"
        );
        require(nonceToTransaction[_nonce].executed == false, "Already executed.");
        require(nonceToTransaction[_nonce].value<=address(this).balance);
        nonceToTransaction[_nonce].executed = true;

       ( bool txSuccess,) = (nonceToTransaction[_nonce].toAddress).call{value: nonceToTransaction[_nonce].value}(nonceToTransaction[_nonce].txData); //!!!!!

        if(!txSuccess) nonceToTransaction[_nonce].executed = false;
        emit Executed(msg.sender,_nonce,txSuccess);
        return txSuccess;

        //
    }

}

contract SampleA {
uint public val;

function increment() external {
    val++;
}
function getFnData() public pure  returns(bytes memory) {
return abi.encodeWithSignature("increment()");
}

}

