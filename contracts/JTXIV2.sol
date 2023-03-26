// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./JTXI.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract JTXV2 is JTXI {
    struct Presale {
        IERC20 token;
        uint256 tokenPrice; // in wei
        uint256 tokensSold;
        uint256 startTime;
        uint256 endTime;
        uint256 maxTokens;
        bool isPaused;
    }

    AggregatorV3Interface internal priceFeed;

    Presale[] public presales;
    mapping(uint256 => uint256) public presaleIndex;
    event PresaleAdded(
        uint256 indexed presaleIndex,
        address tokenAddress,
        uint256 maxTokens,
        uint256 presaleStartTime,
        uint256 presaleEndTime,
        uint256 tokenPrice
    );
    event TokensPurchased(
        uint256 indexed presaleIndex,
        address indexed buyer,
        uint256 tokensPurchased
    );
    event PresalePaused(uint256 indexed presaleIndex);
    event PresaleUnpaused(uint256 indexed presaleIndex);

    // constructor(address _priceFeedAddress) {
    //     priceFeed = AggregatorV3Interface(_priceFeedAddress);
    // }

    function setPriceFeedAddress(address _priceFeedAddress) external onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function addPresale(
        address _token,
        uint256 _maxTokens,
        uint256 _presaleStartTime,
        uint256 _presaleEndTime,
        uint256 _tokenPrice
    ) external onlyOwner {
        require(
            address(priceFeed) != address(0),
            "Aggregator price feed not set"
        );
        require(_maxTokens > 0, "Max tokens must be greater than zero");
        require(
            _presaleStartTime > block.timestamp,
            "Presale start time must be in the future"
        );
        require(
            _presaleEndTime > _presaleStartTime,
            "Presale end time must be after start time"
        );
        require(_tokenPrice > 0, "Token price must be greater than zero");

        Presale memory newPresale = Presale(
            IERC20(_token),
            _tokenPrice,
            0,
            _presaleStartTime,
            _presaleEndTime,
            _maxTokens,
            false
        );

        uint256 allowance = IERC20(_token).allowance(msg.sender, address(this));
        require(
            allowance >= _maxTokens,
            "Allowance not enough to transfer tokens to presale contract"
        );

        IERC20(_token).transferFrom(msg.sender, address(this), _maxTokens);

        uint256 index = presales.length;
        presales.push(newPresale);
        presaleIndex[index] = index;
        emit PresaleAdded(
            index,
            _token,
            _maxTokens,
            _presaleStartTime,
            _presaleEndTime,
            _tokenPrice
        );
    }

    function buyTokens(
        uint256 _presaleIndex,
        uint256 _tokensToBuy
    ) external payable {
        Presale storage presale = presales[presaleIndex[_presaleIndex]];
        require(
            block.timestamp >= presale.startTime &&
                block.timestamp <= presale.endTime,
            "Presale not active"
        );
        require(!presale.isPaused, "Presale is paused");
        require(
            presale.tokensSold + _tokensToBuy <= presale.maxTokens,
            "Not enough tokens left for sale"
        );
        uint256 totalPrice = _tokensToBuy * presale.tokenPrice;
        require(msg.value == totalPrice, "Incorrect payment amount");

        // (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 bnbToUsd = getLatestPrice();

        // Calculate the maximum number of tokens the buyer can purchase based on the current BNB/USD price
        uint256 maxTokens = (msg.value * bnbToUsd) / presale.tokenPrice;
        require(
            _tokensToBuy <= maxTokens,
            "Token purchase exceeds maximum amount allowed based on the current BNB/USD price"
        );

        presale.tokensSold += _tokensToBuy;
        presale.token.transfer(msg.sender, _tokensToBuy);
        emit TokensPurchased(_presaleIndex, msg.sender, _tokensToBuy);
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        
        return uint256(price);
    }

    function pausePresale(uint256 _presaleIndex) external onlyOwner {
        Presale storage presale = presales[presaleIndex[_presaleIndex]];
        require(presale.isPaused == false, "Presale is already paused");
        presale.isPaused = true;
        emit PresalePaused(_presaleIndex);
    }

    function unpausePresale(uint256 _presaleIndex) external onlyOwner {
        Presale storage presale = presales[presaleIndex[_presaleIndex]];
        require(presale.isPaused == true, "Presale is not paused");
        presale.isPaused = false;
        emit PresaleUnpaused(_presaleIndex);
    }

    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawTokens(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    function version() public pure returns (string memory) {
        return "v2";
    }
}