pragma solidity ^0.4.19;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ECRecovery.sol";
import "./Multisig.sol";

import "./BidirectionalCFLibrary.sol";

/// @title Bidirectional Ether payment channels contract.
contract BidirectionalCF {
    using SafeMath for uint256;

    uint32  public nonce;
    Multisig multisig; // TODO Maybe it is more cool to pass that as sender, receiver addresses

    uint256 public lastUpdate;
    uint256 public settlementPeriod;
    uint256 public toSender;
    uint256 public toReceiver;

    function BidirectionalCF(address _multisig, uint32 _settlementPeriod) public payable {
        multisig = Multisig(_multisig);
        lastUpdate = block.number;
        settlementPeriod = _settlementPeriod;
        nonce = uint32(0);
    }

    function () payable public {}

    function update(uint32 _nonce, uint256 _toSender, uint256 _toReceiver, bytes _senderSig, bytes _receiverSig) public {
        BidirectionalCFLibrary.BidirectionalCFData bidiData;
        bidiData.settlementPeriod = settlementPeriod;
        bidiData.lastUpdate = lastUpdate;
        bidiData.nonce = nonce;
        bidiData.multisig = multisig;

        BidirectionalCFLibrary.update(bidiData, _nonce, _toSender, _toReceiver, _senderSig, _receiverSig);
        toSender = _toSender;
        toReceiver = _toReceiver;
        nonce = _nonce;
        lastUpdate = block.number;
    }

    function close(uint256 _toSender, uint256 _toReceiver, bytes _senderSig, bytes _receiverSig) public {
        require(BidirectionalCFLibrary.canClose(multisig, lastUpdate, settlementPeriod, _toSender, _toReceiver, _senderSig, _receiverSig));
        address sender;
        address receiver;
        uint256 __nonce;
        (sender, receiver, __nonce) = multisig.state();
        receiver.transfer(toReceiver);

        sender.transfer(toSender);
        selfdestruct(multisig);
    }

    function withdraw() public {
        require(!isSettling());

        address sender;
        address receiver;
        uint256 __nonce;
        (sender, receiver, __nonce) = multisig.state();

        receiver.transfer(toReceiver);

        sender.transfer(toSender);
        selfdestruct(multisig); // TODO Use that every time
    }

    /*** CHANNEL STATE ***/

    function isSettling() public view returns(bool) {
        return block.number <= lastUpdate + settlementPeriod;
    }

    function paymentDigest(uint32 _nonce, uint256 _toSender, uint256 _toReceiver) public pure returns(bytes32) {
        return BidirectionalCFLibrary.paymentDigest(_nonce, _toSender, _toReceiver); // TODO Use some contract-internal value
    }

}
