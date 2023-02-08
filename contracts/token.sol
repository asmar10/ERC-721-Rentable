/* SPDX-License-Identifier: MIT */
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract token is ERC20, Ownable {
    modifier notOwner() {
        require(msg.sender != owner(), "only user allowed");
        _;
    }
    uint256 public overallSupply;
    uint256 public reservedForUsers;
    uint256 public reservedForOwner;
    uint256 public ownerCurrentMinted;
    uint256 public userCurrentMinted;

    constructor(uint256 initialSupply) ERC20("myToken", "TKN") {
        overallSupply = initialSupply * 10**18;
        reservedForOwner = overallSupply / 2;
        reservedForUsers = overallSupply / 2;
    }

    function mintAsOwner(uint256 _amount) public onlyOwner {
        uint256 amountInEther = _amount * 10**18;
        require((ownerCurrentMinted + amountInEther) <= reservedForOwner,"limit exceeding");
        ownerCurrentMinted += amountInEther;
        _mint(msg.sender, amountInEther);
    }

    function mintAsUser(uint256 _amount) public notOwner {
        uint256 amountInEther = _amount * 10**18;
        require((userCurrentMinted + amountInEther) <= reservedForUsers,"limit exceeding");
        userCurrentMinted += amountInEther;
        _mint(msg.sender, amountInEther);
    }
}