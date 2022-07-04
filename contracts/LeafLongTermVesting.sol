// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/interfaces/IERC1363.sol";
import "./ERC1363/ERC1363Payable.sol";
import "hardhat/console.sol";

/**
 * @dev There's a cliff period of 45 days and left 270 days to fully withdraw
 */
contract LeafLongTermVesting is Context, ERC1363Payable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct VestingInfo {
        uint256 lockFrom;
        uint256 releasedAmount;
        uint256 totalAmount;
    }

    uint256 constant CLIFF_PERIOD = 45 days; // Tokens are locked for the first 45 days
    uint256 constant LINEAR_PERIOD = 270 days;
    mapping(address => VestingInfo[]) public vestings;
    address[] public vestors;

    event Lock(address user, uint256 amount);
    event Unlock(address user, uint256 amount);

    constructor(IERC1363 acceptedToken_) ERC1363Payable((acceptedToken_)) {}

    /**
     * @dev add an entry to the lock list
     * @param vestor Vestor's address.
     * @param amount Token amount to lock
     */
    function lock(address vestor, uint256 amount) internal {
        require(vestor != address(0), "Vesting/lock: addr should not be null.");
        require(amount > 0, "Vesting/lock: amount should be greater than 0.");

        VestingInfo[] storage vestingArr = vestings[vestor];
        if (vestingArr.length == 0) vestors.push(vestor);
        vestingArr.push(VestingInfo(block.timestamp, 0, amount));

        console.log(
            "User %s have locked %d token",
            vestor,
            vestingArr[vestingArr.length - 1].totalAmount
        );
        emit Lock(vestor, amount);
    }

    /**
     * @dev this function is called after the user called transferAndCall function
     * @param operator The address that locked tokens
     * @param sender Representing the previous owner of the given token value
     * @param amount The amount to lock
     * @param data The recipients list that the operator want to distribute tokens to
     */
    function _transferReceived(
        address operator,
        address sender,
        uint256 amount,
        bytes memory data
    ) internal override {
        console.log("Vesting : TransferReceived Function");

        if (data.length == 0) {
            // lock tokens to operator's address
            lock(operator, amount);
            console.log("Receiver %s gets %d tokens", operator, amount);
        } else {
            // distribute total token to multiple recipients
            (address[] memory addresses, uint256[] memory amounts) = abi.decode(
                data,
                (address[], uint256[])
            );
            require(
                addresses.length == amounts.length,
                "Vesting/_transferReceived: Length mismatch in recipients list."
            );

            uint256 totalAmount = 0;
            for (uint32 i = 0; i < amounts.length; i++) {
                totalAmount += amounts[i];
            }

            require(
                totalAmount == amount,
                "Vesting/_transferReceived: Recipients amounts mismatches with total amount."
            );
            for (uint32 i = 0; i < addresses.length; i++) {
                lock(addresses[i], amounts[i]);
            }
        }
    }

    /**
     * @dev Withdraw available locked tokens
     */
    function withdraw() external {
        address vestor = _msgSender();
        uint256 vestingLength = vestings[vestor].length;
        uint256 totalWithdrawAmount = 0;

        for (uint256 i = 0; i < vestingLength; i++) {
            uint256 unlockable = getUnlockable(i, vestor);
            if (unlockable > 0) {
                VestingInfo[] storage vestingArr = vestings[vestor];
                vestingArr[i].releasedAmount = vestingArr[i].releasedAmount.add(
                    unlockable
                );
                totalWithdrawAmount = totalWithdrawAmount.add(unlockable);
            }
        }
        IERC20(acceptedToken()).safeTransfer(vestor, totalWithdrawAmount); // withdraw total token to user
        emit Unlock(vestor, totalWithdrawAmount);
    }

    /**
     * @dev Get unlockable amount in vestings
     * @param index Vested index in user's vestings
     * @param vestor Vestor's address
     */
    function getUnlockable(uint256 index, address vestor)
        internal
        view
        returns (uint256)
    {
        VestingInfo memory vestingInfo = vestings[vestor][index];

        if (vestingInfo.totalAmount == 0) return 0;
        if (vestingInfo.lockFrom.add(CLIFF_PERIOD) > block.timestamp) return 0;

        uint256 lockedPeriod = block.timestamp.sub(vestingInfo.lockFrom).sub(
            CLIFF_PERIOD
        );
        // 10% is unlocked after cliff period
        uint256 releasablePercent = 10 +
            lockedPeriod.mul(90).div(LINEAR_PERIOD);

        if (releasablePercent > 100) releasablePercent = 100;
        uint256 releasable = vestingInfo.totalAmount.mul(releasablePercent).div(
            100
        );

        return
            releasable >= vestingInfo.releasedAmount
                ? releasable.sub(vestingInfo.releasedAmount)
                : 0;
    }

    /**
     * @dev Get the length of total vests by all users
     * @param offset Starting index of vestors
     * @param limit Limit to get in vestors array
     */
    function getVestingLength(uint256 offset, uint256 limit)
        internal
        view
        returns (uint256)
    {
        uint256 totalLength = 0;

        for (uint256 i = offset; i < (offset + limit); i++) {
            if (i < vestors.length) {
                VestingInfo[] memory userVesting = vestings[vestors[i]];
                totalLength = totalLength.add(userVesting.length);
            }
        }
        return totalLength;
    }

    /**
     * @dev Get the length of vestors
     */
    function getVestorsLength() external view returns (uint256) {
        return vestors.length;
    }

    /**
     * @dev Get vesting details of users by offset and limit
     * @param offset Starting index of vestors
     * @param limit Limit to get in vestors array
     */
    function getVestingInfos(uint256 offset, uint256 limit)
        external
        view
        returns (
            address[] memory addresses,
            uint256[] memory ids,
            uint256[] memory lockFrom,
            uint256[] memory releasedAmount,
            uint256[] memory releasableAmount,
            uint256[] memory totalAmount
        )
    {
        uint256 length = getVestingLength(offset, limit);

        addresses = new address[](length);
        ids = new uint256[](length);
        lockFrom = new uint256[](length);
        releasedAmount = new uint256[](length);
        releasableAmount = new uint256[](length);
        totalAmount = new uint256[](length);
        uint256 index = 0;

        for (uint256 i = offset; i < (offset + limit); i++) {
            if (i < vestors.length) {
                address vestor = vestors[i];

                for (uint256 j = 0; j < vestings[vestor].length; j++) {
                    addresses[index] = vestor;
                    ids[index] = j;
                    lockFrom[index] = vestings[vestor][j].lockFrom;
                    releasedAmount[index] = vestings[vestor][j].releasedAmount;
                    releasableAmount[index] = getUnlockable(j, vestor);
                    totalAmount[index] = vestings[vestor][j].totalAmount;
                    index += 1;
                }
            }
        }
    }

    /**
     * @dev Get vesting detail of a vestor
     * @param vestor Address of a vestor
     */
    function getVestingInfo(address vestor)
        external
        view
        returns (
            uint256[] memory ids,
            uint256[] memory lockFrom,
            uint256[] memory releasedAmount,
            uint256[] memory relesableAmount,
            uint256[] memory totalAmount
        )
    {
        ids = new uint256[](vestings[vestor].length);
        lockFrom = new uint256[](vestings[vestor].length);
        releasedAmount = new uint256[](vestings[vestor].length);
        relesableAmount = new uint256[](vestings[vestor].length);
        totalAmount = new uint256[](vestings[vestor].length);

        for (uint256 i = 0; i < vestings[vestor].length; i++) {
            ids[i] = i;
            lockFrom[i] = vestings[vestor][i].lockFrom;
            releasedAmount[i] = vestings[vestor][i].releasedAmount;
            relesableAmount[i] = getUnlockable(i, vestor);
            totalAmount[i] = vestings[vestor][i].totalAmount;
        }
    }
}
