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
    uint256 public presaleId;
    uint256 public USDT_MULTIPLIER;
    uint256 public ETH_MULTIPLIER;
    address public fundReceiver;
    struct Presale {
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256 Sold;
        uint256 tokensToSell;
        uint256 amountRaised;
        bool Active;
    }

    AggregatorV3Interface internal _priceFeed;

    // https://docs.chain.link/docs/ethereum-addresses/ => (ETH / USD)

    mapping(uint256 => bool) public paused;
    mapping(uint256 => Presale) public presale;

    IERC20 public SaleToken;

    event PresaleCreated(
        uint256 indexed _id,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime
    );

    event PresaleUpdated(
        bytes32 indexed key,
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );

    event TokensBought(
        address indexed user,
        uint256 indexed id,
        uint256 tokensBought,
        uint256 amountPaid,
        uint256 timestamp
    );

  

    event PresaleTokenAddressUpdated(
        address indexed prevValue,
        address indexed newValue,
        uint256 timestamp
    );

    event PresalePaused(uint256 indexed id, uint256 timestamp);
    event PresaleUnpaused(uint256 indexed id, uint256 timestamp);

    function setPriceFeedAddress(address _priceFeedAddress) external onlyOwner {
        _priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function ChangeTokenToSell(address _token) public onlyOwner {
        SaleToken = IERC20(_token);
    }

    // /**
    //  * @dev Creates a new presale
    //  * @param _price Per token price multiplied by (10**18)
    //  * @param _tokensToSell No of tokens to sell
    //  */
    function createPresale(
        uint256 _price,
        uint256 _tokensToSell
    ) external onlyOwner {
        require(_price > 0, "Zero price");
        require(_tokensToSell > 0, "Zero tokens to sell");
        require(presale[presaleId].Active == false, "Previous Sale is Active");

        presaleId++;

        presale[presaleId] = Presale(0, 0, _price, 0, _tokensToSell, 0, false);

        emit PresaleCreated(presaleId, _tokensToSell, 0, 0);
    }

    function startPresale() public onlyOwner {
        presale[presaleId].startTime = block.timestamp;
        presale[presaleId].Active = true;
    }

    function endPresale() public onlyOwner {
        require(
            presale[presaleId].Active = true,
            "This presale is already Inactive"
        );
        presale[presaleId].endTime = block.timestamp;
        presale[presaleId].Active = false;
    }

    modifier checkPresaleId(uint256 _id) {
        require(_id > 0 && _id <= presaleId, "Invalid presale id");
        _;
    }

    modifier checkSaleState(uint256 _id) {
        require(
            block.timestamp >= presale[_id].startTime &&
                presale[_id].Active == true,
            "Invalid time for buying"
        );
        
        _;
    }

    function updatePresale(
        uint256 _id,
        uint256 _price,
        uint256 _tokensToSell
    ) external checkPresaleId(_id) onlyOwner {
        require(_price > 0, "Zero price");
        require(_tokensToSell > 0, "Zero tokens to sell");
        presale[_id].price = _price;
        presale[_id].tokensToSell = _tokensToSell;
    }

    function pausePresale(uint256 _id) external checkPresaleId(_id) onlyOwner {
        require(!paused[_id], "Already paused");
        paused[_id] = true;
        emit PresalePaused(_id, block.timestamp);
    }

    /**
     * @dev To unpause the presale
     * @param _id Presale id to update
     */
    function unPausePresale(
        uint256 _id
    ) external checkPresaleId(_id) onlyOwner {
        require(paused[_id], "Not paused");
        paused[_id] = false;
        emit PresaleUnpaused(_id, block.timestamp);
    }


      /**
     * @dev To get latest ethereum price in 10**18 format
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = _priceFeed.latestRoundData();
        return uint256(price);
    }

     function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    
    

     function buyTokens() checkPresaleId(presaleId) checkSaleState(presaleId) public payable returns (bool){
        require(_priceFeed != AggregatorV3Interface(address(0)), "Price feed cannot be null");
        require(address(SaleToken) != address(0), "Sale token address cannot be null");
        require(msg.value>0,"Value of send bnb must be grate than 0;");
        require(presale[presaleId].price>0,"Value of send bnb must be grate than 0;");
        require(!paused[presaleId], "Presale paused");
        require(presale[presaleId].Active == true, "Presale is not active yet");

        uint256 bnbAmount = msg.value;
        uint256 usdPrice = getLatestPrice();
        uint256 tokenAmount = (bnbAmount * usdPrice) / presale[presaleId].price;
        require(tokenAmount > 0, "Insufficient BNB amount");
        require(SaleToken.balanceOf(address(this))>tokenAmount,"Dnt have enough token");

        require(presale[presaleId].Sold + tokenAmount <= presale[presaleId].tokensToSell, "Not enough tokens left for sale");

        presale[presaleId].Sold += tokenAmount;

        SaleToken.transfer(msg.sender, tokenAmount);

       sendValue(payable(fundReceiver), msg.value);

    

        emit TokensBought(msg.sender, presaleId, tokenAmount, bnbAmount, block.timestamp);

        return true;
    }


    function changeFundWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Invalid parameters");
        fundReceiver = _wallet;
    }


    




    function WithdrawTokens(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(fundReceiver, amount);
    }

    function WithdrawContractFunds(uint256 amount) external onlyOwner {
        sendValue(payable(fundReceiver), amount);
    }

}
