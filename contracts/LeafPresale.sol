// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC1363.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "hardhat/console.sol";

/**
 * @dev LeafPresale is a base contract for managing a vested token sale
 * allowing investors to exchange ETH for vested tokens.
 */
contract LeafPresale is ReentrancyGuard, Context, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct PresaleInfo {
        uint256 depositAmount; // Funds token amount per recipient.
        uint256 tokenAmount; // Rewards token that needs to be vested.
    }

    uint256 public minAcceptAmount; // Minimum amount required to deposit in wei
    uint256 public leafValueInWei; // Leaf token value in wei for presale

    mapping(address => PresaleInfo) public recipients; // Presale Buyers
    uint256 public totalLeafSold; // Total amount of leaf token sold

    address public longTermVestingContract; // Vesting Contract
    IERC1363 public leafTokenContract; // Leaf Contract

    event Aborted(uint256 amount);

    /**
     * @dev Constructor of Presale contract
     * @param leafAddress Address of leaf token
     * @param vestingAddress Address of vesting contract
     * @param minAcceptedAmount Minimum accepting amount in wei for presale
     * @param leafInWei Leaf token value in wei for presale
     */
    constructor(
        address leafAddress,
        address vestingAddress,
        uint256 minAcceptedAmount,
        uint256 leafInWei
    ) {
        require(
            address(leafAddress) != address(0x00),
            "Presale/constructor: Not allowed to set null to token contract address."
        );
        require(
            address(vestingAddress) != address(0x00),
            "Presale/constructor: Not allowed to set null to vesting contract address."
        );
        require(
            leafInWei != 0,
            "Presale/constructor: Not allowed to set 0 to leafInnValue Amount."
        );

        leafTokenContract = IERC1363(leafAddress);
        leafValueInWei = leafInWei;
        minAcceptAmount = minAcceptedAmount;
        longTermVestingContract = vestingAddress;
    }

    /**
     * @dev Receive Wei from presale buyers
     * equal to exchange ratio of tokens will be locked in vesting contract
     */
    receive() external payable nonReentrant {
        console.log("---Deposit Fuction Called---");

        require(isPresaleOn(), "Presale/deposit: Presale is not active.");

        require(
            msg.value >= minAcceptAmount,
            "Presale/deposit: Deposited ETH is less than the minimum amount required."
        );

        depositInternal(); // send locked token to vesting
        withdrawToOwner(); // send ether received to owner
    }

    /**
     * @dev Abort the presale and send the left token to owner
     */
    function abort() external onlyOwner {
        uint256 tokenBalance = IERC20(leafTokenContract).balanceOf(
            address(this)
        );

        if (tokenBalance >= 0) {
            address payable owner = payable(owner());
            IERC20(leafTokenContract).safeTransfer(owner, tokenBalance);
            emit Aborted(tokenBalance);
        }
    }

    /**
     * @dev Set Mimimum accepted amount for presale
     */
    function setMinAcceptAmountIn(uint256 value_) external onlyOwner {
        minAcceptAmount = value_;
    }

    /**
     * @dev Set Leaf token value for presale
     * @param value Leaf token value
     */
    function setLeafValueInWei(uint256 value) external onlyOwner {
        require(
            value != 0,
            "Presale/setLeafValueInWei: Not allowed to set 0 to leafInnValue Amount."
        );
        leafValueInWei = value;
    }

    /**
     * @dev Send locked leaf token to vestor
     */
    function depositInternal() internal {
        uint256 weiAmount = msg.value;
        uint256 tokenAmount = weiAmount.mul(10**18).div(leafValueInWei);

        console.log(
            "Available token amount is - %d and amount to buy is %d",
            getLeafTokenBalance(),
            tokenAmount
        );

        require(
            getLeafTokenBalance() >= tokenAmount,
            "Presale/depositInternal: Not enough tokens available."
        );

        address sender = _msgSender();
        recipients[sender].depositAmount = recipients[sender].depositAmount.add(
            weiAmount
        );
        recipients[sender].tokenAmount = recipients[sender].tokenAmount.add(
            tokenAmount
        );

        totalLeafSold = totalLeafSold.add(tokenAmount); // add total sold token amount

        (address[] memory addresses, uint256[] memory amounts) = (
            new address[](1),
            new uint256[](1)
        );
        addresses[0] = sender;
        amounts[0] = tokenAmount;

        // send leaf token to vest contract and it will be locked automatically in vesting contract
        leafTokenContract.transferAndCall(
            longTermVestingContract,
            tokenAmount,
            abi.encode(addresses, amounts)
        );
    }

    /**
     * @dev Withdraw Ether to owner
     */
    function withdrawToOwner() internal {
        uint256 weiBalance = address(this).balance;
        require(
            weiBalance > 0,
            "Presale/withdrawToOwner: No ETH balance to withdraw."
        );

        address payable owner = payable(owner());
        (bool success, ) = owner.call{value: weiBalance}("");
        require(success, "Presale/withdrawToOwner: Transfer failed.");
    }

    /**
     * @dev Available leaf token amount for presale
     */
    function getLeafTokenBalance() public view returns (uint256) {
        require(
            address(leafTokenContract) != address(0x00),
            "Presale/getLeafTokenBalance: Set leaf token contract!"
        );

        return leafTokenContract.balanceOf(address(this));
    }

    /**
     * @dev Return true if presale is ongoing, otherwise false
     */
    function isPresaleOn() public view returns (bool) {
        if (leafTokenContract.balanceOf(address(this)) > 0) {
            return true;
        } else {
            return false;
        }
    }
}
