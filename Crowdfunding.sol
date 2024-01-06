// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Crowdfunding is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    event PaymentReceived(address indexed contributor, uint256 amount, uint256 convertedAmount, address tokenAddress);

    IERC20 public stablecoin;
    uint256 public conversionRate;
    uint256 public totalCollected;

    constructor(address _stablecoinAddress, uint256 _initialConversionRate) {
        require(_stablecoinAddress != address(0), "Stablecoin address cannot be zero");
        stablecoin = IERC20(_stablecoinAddress);
        conversionRate = _initialConversionRate;
    }

    function receivePayment(uint256 amount) external payable whenNotPaused nonReentrant {
        require(msg.value == amount, "Payment amount mismatch");
        uint256 convertedAmount = convertToStablecoin(amount);
        stablecoin.safeTransfer(msg.sender, convertedAmount);
        totalCollected += convertedAmount;
        emit PaymentReceived(msg.sender, amount, convertedAmount, address(stablecoin));
    }

    function setConversionRate(uint256 newConversionRate) external onlyOwner {
        require(newConversionRate > 0, "Conversion rate must be greater than zero");
        conversionRate = newConversionRate;
    }

    function convertToStablecoin(uint256 amount) internal view returns (uint256) {
        return amount * conversionRate;
    }

    function withdrawFunds(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Cannot withdraw to zero address");
        require(amount <= totalCollected, "Insufficient funds");
        stablecoin.safeTransfer(to, amount);
        totalCollected -= amount;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function emergencyWithdraw(address to, uint256 amount) external onlyOwner whenPaused nonReentrant {
        require(to != address(0), "Cannot withdraw to zero address");
        stablecoin.safeTransfer(to, amount);
    }
}