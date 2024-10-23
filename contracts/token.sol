/**
 *Submitted for verification at Etherscan.io on 2024-06-30
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero"); // Solidity automatically throws when dividing by 0
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(
        address tokenOwner
    ) external view returns (uint256 balance);
    function allowance(
        address tokenOwner,
        address spender
    ) external view returns (uint256 remaining);
    function transfer(
        address to,
        uint256 value
    ) external returns (bool success);
    function approve(
        address spender,
        uint256 value
    ) external returns (bool success);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 value
    );
    event Mint(address indexed to, uint256 value);
}

contract GigaTronix is ERC20Interface {
    using SafeMath for uint256;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 private _totalSupply = 0;
    address public owner;
    uint256 private _maxSupply;

    event Active(address msgSender);
    event Reset(address msgSender);

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    constructor() {
        symbol = "GTX";
        name = "Giga Tronix";
        decimals = 18;
        _maxSupply = 5000000000 * 10 ** uint256(decimals);
        _totalSupply = _maxSupply;
        owner = msg.sender;
        balances[owner] = _maxSupply;
        emit Transfer(address(0), owner, _maxSupply);
    }

    function isOwner(address add) public view returns (bool) {
        return add == owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Caller is not the owner");
        _;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function balanceOf(
        address tokenOwner
    ) public view override returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function allowance(
        address tokenOwner,
        address spender
    ) public view override returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }

    function transfer(
        address to,
        uint256 value
    ) public override returns (bool success) {
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(
        address spender,
        uint256 value
    ) public override returns (bool success) {
        require(value > 0, "Invalid value");

        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        require(spender != address(0), "Invalid address");
        require(addedValue > 0, "Invalid value");

        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(
            addedValue
        );
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        require(spender != address(0), "Invalid address");
        require(subtractedValue > 0, "Invalid value");
        require(
            subtractedValue <= allowed[msg.sender][spender],
            "Allowance exceeded"
        );

        allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(
            subtractedValue
        );
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool success) {
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");
        require(value <= allowed[from][msg.sender], "Allowance exceeded");

        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }

    function withdrawEth() external onlyOwner {
        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }
    function withdrawTokens(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        ERC20Interface(_token).transfer(owner, _amount);
    }
}
