// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "chainlink/ChainlinkClient.sol";

contract FightController is ChainlinkClient {
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    bool private winnerA;
    bool private winnerB;

    constructor(
        address _link,
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) {
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        setChainlinkOracle(_oracle);

        jobId = _jobId;
        fee = _fee;
    }

    function requestData(uint256 _fightId) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        return sendChainlinkRequest(req, fee);
    }

    function fulfill(bytes32 _requestId, bool data)
        public
        recordChainlinkFulfillment(_requestId)
    {}
}
