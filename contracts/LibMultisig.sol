pragma solidity ^0.4.19;

import "zeppelin-solidity/contracts/ECRecovery.sol";

import "./LibCommon.sol";

library LibMultisig {
    struct State {
        address sender;
        address receiver;
        uint256 nonce;
    }

    // TODO Make it different for call and delegatecall
    function executionHash(address _self, address _destination, uint256 _value, bytes _data, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(
            _self,
            _destination,
            _value,
            _data,
            _nonce
        );
    }

    function executeHashCheck(address destination, uint256 value, bytes data, bytes senderSig, bytes receiverSig, State storage state) public view {
        bytes32 hash = LibCommon.recoveryDigest(executionHash(address(this), destination, value, data, state.nonce));
        require(state.sender == ECRecovery.recover(hash, senderSig));
        require(state.receiver == ECRecovery.recover(hash, receiverSig));
    }

    function execute(
        address destination,
        uint256 value,
        bytes data,
        bytes senderSig,
        bytes receiverSig,
        State storage state
    ) public
    {
        executeHashCheck(destination, value, data, senderSig, receiverSig, state);
        state.nonce++;
    }

    function executeDelegate(
        address destination,
        uint256 value,
        bytes data,
        bytes senderSig,
        bytes receiverSig,
        State storage state
    ) public
    {
        executeHashCheck(destination, value, data, senderSig, receiverSig, state);
        state.nonce++;
    }
}
