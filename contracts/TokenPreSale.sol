// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract TokenPreSale is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    uint256 public presaleId;
    uint256 public BASE_MULTIPLIER;

    struct Presale {
        address saleToken;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256 tokensToSell;
        uint256 baseDecimals;
        uint256 inSale;
        bool enableBuyWithEth;
        bool enableBuyWithUsdt;
    }

    IERC20 public USDTInterface;
    AggregatorV3Interface internal aggregatorInterface;

    mapping(uint256 => bool) public paused;
    mapping(uint256 => Presale) public presale;

    event PresaleCreated(
        uint256 indexed _id,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        bool enableBuyWithEth,
        bool enableBuyWithUsdt
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
        address indexed purchaseToken,
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

    constructor() {}

    function initialize(address _oracle, address _usdt) external initializer {
        require(_oracle != address(0), "PreSale: Zero aggregator address");
        require(_usdt != address(0), "PreSale: Zero USDT address");
        __Ownable_init_unchained(msg.sender);
        __ReentrancyGuard_init_unchained();
        aggregatorInterface = AggregatorV3Interface(_oracle);
        USDTInterface = IERC20(_usdt);
        BASE_MULTIPLIER = 10 ** 18;
    }

    function createPresale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _price,
        uint256 _tokensToSell,
        uint256 _baseDecimals,
        bool _enableBuyWithEth,
        bool _enableBuyWithUsdt
    ) external onlyOwner {
        require(
            _startTime > block.timestamp && _endTime > _startTime,
            "PreSale: Invalid time"
        );
        require(_price > 0, "PreSale: Zero price");
        require(_tokensToSell > 0, "PreSale: Zero tokens to sell");
        require(_baseDecimals > 0, "PreSale: Zero decimals for the token");

        presaleId++;
        presale[presaleId] = Presale({
            saleToken: address(0),
            startTime: _startTime,
            endTime: _endTime,
            price: _price,
            tokensToSell: _tokensToSell,
            baseDecimals: _baseDecimals,
            inSale: _tokensToSell,
            enableBuyWithEth: _enableBuyWithEth,
            enableBuyWithUsdt: _enableBuyWithUsdt
        });

        emit PresaleCreated(
            presaleId,
            _tokensToSell,
            _startTime,
            _endTime,
            _enableBuyWithEth,
            _enableBuyWithUsdt
        );
    }

    function changeSaleTimes(
        uint256 _id,
        uint256 _startTime,
        uint256 _endTime
    ) external checkPresaleId(_id) onlyOwner {
        require(_startTime > 0 || _endTime > 0, "PreSale: Invalid parameters");

        if (_startTime > 0) {
            require(
                block.timestamp < presale[_id].startTime,
                "Sale already started"
            );
            require(block.timestamp < _startTime, "PreSale: Sale time in past");
            uint256 prevValue = presale[_id].startTime;
            presale[_id].startTime = _startTime;
            emit PresaleUpdated(
                bytes32("START"),
                prevValue,
                _startTime,
                block.timestamp
            );
        }

        if (_endTime > 0) {
            require(
                block.timestamp < presale[_id].endTime,
                "PreSale: Sale already ended"
            );
            require(
                _endTime > presale[_id].startTime,
                "PreSale: Invalid endTime"
            );
            uint256 prevValue = presale[_id].endTime;
            presale[_id].endTime = _endTime;
            emit PresaleUpdated(
                bytes32("END"),
                prevValue,
                _endTime,
                block.timestamp
            );
        }
    }

    function changeSaleTokenAddress(
        uint256 _id,
        address _newAddress
    ) external checkPresaleId(_id) onlyOwner {
        require(_newAddress != address(0), "PreSale: Zero token address");
        address prevValue = presale[_id].saleToken;
        presale[_id].saleToken = _newAddress;
        emit PresaleTokenAddressUpdated(
            prevValue,
            _newAddress,
            block.timestamp
        );
    }

    function changePrice(
        uint256 _id,
        uint256 _newPrice
    ) external checkPresaleId(_id) onlyOwner {
        require(_newPrice > 0, "PreSale: Zero price");
        require(
            presale[_id].startTime > block.timestamp,
            "PreSale: Sale already started"
        );
        uint256 prevValue = presale[_id].price;
        presale[_id].price = _newPrice;
        emit PresaleUpdated(
            bytes32("PRICE"),
            prevValue,
            _newPrice,
            block.timestamp
        );
    }

    function changeEnableBuyWithEth(
        uint256 _id,
        bool _enableToBuyWithEth
    ) external checkPresaleId(_id) onlyOwner {
        bool prevValue = presale[_id].enableBuyWithEth;
        presale[_id].enableBuyWithEth = _enableToBuyWithEth;
        emit PresaleUpdated(
            bytes32("ENABLE_BUY_WITH_ETH"),
            prevValue ? 1 : 0,
            _enableToBuyWithEth ? 1 : 0,
            block.timestamp
        );
    }

    function changeEnableBuyWithUsdt(
        uint256 _id,
        bool _enableToBuyWithUsdt
    ) external checkPresaleId(_id) onlyOwner {
        bool prevValue = presale[_id].enableBuyWithUsdt;
        presale[_id].enableBuyWithUsdt = _enableToBuyWithUsdt;
        emit PresaleUpdated(
            bytes32("ENABLE_BUY_WITH_USDT"),
            prevValue ? 1 : 0,
            _enableToBuyWithUsdt ? 1 : 0,
            block.timestamp
        );
    }

    function pausePresale(uint256 _id) external checkPresaleId(_id) onlyOwner {
        require(!paused[_id], "PreSale: Already paused");
        paused[_id] = true;
        emit PresalePaused(_id, block.timestamp);
    }

    function unpausePresale(
        uint256 _id
    ) external checkPresaleId(_id) onlyOwner {
        require(paused[_id], "PreSale: Not paused");
        paused[_id] = false;
        emit PresaleUnpaused(_id, block.timestamp);
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        price = price * (10 ** 10); // 8 decimals to 18 decimals
        return uint256(price);
    }

    modifier checkPresaleId(uint256 _id) {
        require(_id > 0 && _id <= presaleId, "PreSale: Invalid presale id");
        _;
    }

    function buyWithEth(
        uint256 _id
    ) external payable checkPresaleId(_id) nonReentrant returns (bool) {
        require(
            presale[_id].saleToken != address(0),
            "PreSale: Token address not set"
        );
        require(
            presale[_id].startTime <= block.timestamp,
            "PreSale: Presale not started"
        );
        require(
            presale[_id].endTime >= block.timestamp,
            "PreSale: Presale ended"
        );
        require(presale[_id].enableBuyWithEth, "PreSale: Disabled");
        require(!paused[_id], "PreSale: Presale paused");

        uint256 usdPrice = getLatestPrice();
        uint256 usdAmount = (msg.value * usdPrice) / BASE_MULTIPLIER;
        uint256 tokens = (usdAmount / presale[_id].price) *
            (10 ** presale[_id].baseDecimals);

        require(
            presale[_id].inSale >= tokens,
            "PreSale: Insufficient tokens left"
        );

        presale[_id].inSale -= tokens;
        IERC20(presale[_id].saleToken).transfer(_msgSender(), tokens);

        // (bool success, bytes memory data) = presale[_id].saleToken.call(
        //     abi.encodeWithSignature(
        //         "freeze(address,uint256)",
        //         _msgSender(),
        //         tokens
        //     )
        // );
        // require(success, "PreSale: Token freeze failed");

        emit TokensBought(
            _msgSender(),
            _id,
            address(0),
            tokens,
            msg.value,
            block.timestamp
        );

        return true;
    }
    function buyWithUsdt(
        uint256 _id,
        uint256 amount
    ) external checkPresaleId(_id) nonReentrant returns (bool) {
        require(
            presale[_id].saleToken != address(0),
            "PreSale:  Token address not set"
        );
        require(
            presale[_id].startTime <= block.timestamp,
            "PreSale: Presale not started"
        );
        require(
            presale[_id].endTime >= block.timestamp,
            "PreSale:  Presale ended"
        );
        require(presale[_id].enableBuyWithUsdt, "PreSale: Disabled");
        require(!paused[_id], "PreSale:  Presale paused");

        // Check the allowance
        uint256 allowance = USDTInterface.allowance(
            _msgSender(),
            address(this)
        );
        require(allowance >= amount, "PreSale:  Insufficient USDT allowance");

        uint256 tokens = (amount / presale[_id].price) *
            (10 ** presale[_id].baseDecimals);
        require(
            presale[_id].inSale >= tokens,
            "PreSale:  Insufficient tokens left"
        );

        presale[_id].inSale -= tokens;
        USDTInterface.transferFrom(_msgSender(), owner(), amount);
        IERC20(presale[_id].saleToken).transfer(_msgSender(), tokens);

        // (bool success, bytes memory data) = presale[_id].saleToken.call(
        //     abi.encodeWithSignature(
        //         "freeze(address,uint256)",
        //         _msgSender(),
        //         tokens
        //     )
        // );
        // require(success, "PreSale: PreSale: Token freeze failed");

        emit TokensBought(
            _msgSender(),
            _id,
            address(USDTInterface),
            tokens,
            amount,
            block.timestamp
        );

        return true;
    }

    function changeBaseMultiplier(uint256 _baseMultiplier) external onlyOwner {
        require(_baseMultiplier > 0, "PreSale: Zero multiplier");
        uint256 prevValue = BASE_MULTIPLIER;
        BASE_MULTIPLIER = _baseMultiplier;
        emit PresaleUpdated(
            bytes32("BASE_MULTIPLIER"),
            prevValue,
            _baseMultiplier,
            block.timestamp
        );
    }

    function changeUsdtAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "PreSale: Zero USDT address");
        address prevValue = address(USDTInterface);
        USDTInterface = IERC20(_newAddress);
        emit PresaleTokenAddressUpdated(
            prevValue,
            _newAddress,
            block.timestamp
        );
    }
    function withdrawEth() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }
    function withdrawTokens(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }
}
