// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KWAToken is ERC20, Ownable {
    uint256 public constant TAX_PERCENTAGE = 5;
    uint256 public cap;
    address public treasury;

    mapping(address => bool) public blacklist;

    event Blacklisted(address indexed user);
    event TreasuryUpdated(address indexed newTreasury);
    event TaxTransferred(address indexed from, address indexed to, uint256 taxAmount);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        uint256 cap_,
        address initialOwner,
        address treasury_
    ) ERC20(name_, symbol_) Ownable(initialOwner) {
        require(treasury_ != address(0), "KWAToken:: Treasury address cannot be the zero address");
        require(cap_ >= initialSupply, "KWAToken:: Cap less than initial supply");
        treasury = treasury_;
        cap = cap_;

        _mint(msg.sender, initialSupply);
    }

    // ===== External =====
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!blacklist[msg.sender] && !blacklist[recipient], "KWAToken:: Address is blacklisted");

        uint256 taxAmount = (amount * TAX_PERCENTAGE) / 100;
        uint256 transferAmount = amount - taxAmount;

        _transfer(_msgSender(), treasury, taxAmount);
        _transfer(_msgSender(), recipient, transferAmount);

        emit TaxTransferred(_msgSender(), recipient, taxAmount);
        
        return true;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= cap, "KWAToken:: Cap exceeded");
        require(!blacklist[to], "KWAToken:: User is blacklisted");

        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        require(!blacklist[from], "KWAToken:: User is blacklisted");

        _burn(from, amount);
    }

    function addToBlacklist(address user) external onlyOwner {
        require(!blacklist[user], "KWAToken:: User already blacklisted");
        blacklist[user] = true;

        emit Blacklisted(user);
    }

    function removeFromBlacklist(address user) external onlyOwner {
        require(blacklist[user], "KWAToken:: User not blacklisted");
        blacklist[user] = false;
    }

    function updateTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "KWAToken:: Treasury address cannot be the zero address");
        treasury = newTreasury;

        emit TreasuryUpdated(newTreasury);
    }

    // ===== View =====
    function isBlacklisted(address user) public view returns(bool) {
        return blacklist[user];
    }

}
