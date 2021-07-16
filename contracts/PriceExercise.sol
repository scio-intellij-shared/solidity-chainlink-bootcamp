pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/vendor/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract PriceExercise is ChainlinkClient {
    bool public priceFeedGreater;
    int256 public storedPrice;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    AggregatorV3Interface internal priceFeed;

    // OK
    constructor(address _oracle, string memory _jobId, uint256 _fee, address _link, address _priceFeed) public 
    {
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        
        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
        fee = _fee;

        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // OK
    function requestPriceData() public returns (bytes32 requestId)
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        request.add("get", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=BTC&tsyms=USD");
        request.add("path", "RAW.BTC.USD.PRICE");

        int timesAmount = 10**18;
        request.addInt("times", timesAmount);

        return sendChainlinkRequestTo(oracle, request, fee);
    }

    // OK
    function fulfill(bytes32 _requestId, int256 _price) public recordChainlinkFulfillment(_requestId) {
        storedPrice = _price;
        if(getLatestPrice() > storedPrice) priceFeedGreater = true;
        else priceFeedGreater = false;
    }

    // OK
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}