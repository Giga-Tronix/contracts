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
    bool public activeStatus = true;
    uint256 private _maxSupply;

    event Active(address msgSender);
    event Reset(address msgSender);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    mapping(address => uint256) public balances;
    mapping(address => uint256) public freezeList;
    mapping(address => mapping(address => uint256)) public allowed;

    constructor() {
        symbol = "GTX";
        name = "Giga Tronix";
        decimals = 18;
        _maxSupply = 50000000000 * 10 ** uint256(decimals);
        owner = msg.sender;
    }

    function isOwner(address add) public view returns (bool) {
        return add == owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Caller is not the owner");
        _;
    }

    modifier onlyActive() {
        require(activeStatus, "Contract is not active");
        _;
    }

    function activeMode() public onlyOwner {
        activeStatus = true;
        emit Active(msg.sender);
    }

    function resetMode() public onlyOwner {
        activeStatus = false;
        emit Reset(msg.sender);
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

    function frozenBalanceOf(address tokenOwner) public view returns (uint256) {
        return freezeList[tokenOwner];
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
    ) public override onlyActive returns (bool success) {
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");
        require(
            balances[msg.sender].sub(freezeList[msg.sender]) >= value,
            "Insufficient available balance"
        );

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(
        address spender,
        uint256 value
    ) public override onlyActive returns (bool success) {
        require(value > 0, "Invalid value");

        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override onlyActive returns (bool success) {
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");
        require(
            balances[from].sub(freezeList[from]) >= value,
            "Insufficient available balance"
        );
        require(value <= allowed[from][msg.sender], "Allowance exceeded");

        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }

    function burn(uint256 value) public onlyActive returns (bool success) {
        require(
            balances[msg.sender].sub(freezeList[msg.sender]) >= value,
            "Insufficient available balance"
        );
        require(value > 0, "Invalid value");

        balances[msg.sender] = balances[msg.sender].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Burn(msg.sender, value);
        return true;
    }

    function freeze(
        address account,
        uint256 value
    ) public onlyOwner returns (bool success) {
        require(
            balances[account].sub(freezeList[account]) >= value,
            "Insufficient available balance to freeze"
        );
        require(account != address(0), "Invalid address");

        freezeList[account] = freezeList[account].add(value);
        emit Freeze(account, value);
        return true;
    }

    function unfreeze(
        address account,
        uint256 value
    ) public onlyOwner returns (bool success) {
        require(
            freezeList[account] >= value,
            "Insufficient frozen balance to unfreeze"
        );
        require(account != address(0), "Invalid address");

        freezeList[account] = freezeList[account].sub(value);
        emit Unfreeze(account, value);
        return true;
    }

    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");
        require(
            _totalSupply.add(value) <= _maxSupply,
            "Minting exceeds max supply"
        );

        _totalSupply = _totalSupply.add(value);
        balances[to] = balances[to].add(value);
        emit Transfer(address(0), to, value);
        emit Mint(to, value);
        return true;
    }

    receive() external payable {
        revert("Cannot receive Ether");
    }
}
