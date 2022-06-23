// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IERC20Permit.sol";
import "./interfaces/IWeSwapCaller.sol";
import "./interfaces/IWeSwapExchange.sol";
import "./libraries/RevertReasonParser.sol";
import "./libraries/UniversalERC20.sol";

contract WeSwapExchange is IWeSwapExchange, Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using UniversalERC20 for IERC20;

    uint256 private constant _PARTIAL_FILL = 0x01;
    uint256 private constant _SHOULD_CLAIM = 0x02;

    event Swapped(address indexed sender, IERC20 indexed srcToken, IERC20 indexed dstToken, address dstReceiver, uint256 amount, uint256 spentAmount, uint256 returnAmount, uint256 minReturnAmount);

    constructor() public {}

    function swap(
        IWeSwapCaller caller,
        SwapDescription calldata desc,
        IWeSwapCaller.CallDescription[] calldata calls
    ) external payable whenNotPaused returns (uint256 returnAmount) {
        require(desc.minReturnAmount > 0, "Min return should not be 0");
        require(calls.length > 0, "Call data should exist");

        uint256 flags = desc.flags;
        IERC20 srcToken = desc.srcToken;
        IERC20 dstToken = desc.dstToken;

        bool srcETH = srcToken.isETH();
        require(msg.value == (srcToken.isETH() ? desc.amount : 0), "Invalid msg.value");

        if (flags & _SHOULD_CLAIM != 0) {
            require(!srcETH, "Claim token is ETH");
            _claim(srcToken, desc.srcReceiver, desc.amount, desc.permit);
        }

        address dstReceiver = (desc.dstReceiver == address(0)) ? msg.sender : desc.dstReceiver;
        uint256 initialSrcBalance = (flags & _PARTIAL_FILL != 0) ? srcToken.universalBalanceOf(msg.sender) : 0;
        uint256 initialDstBalance = dstToken.universalBalanceOf(dstReceiver);

        caller.makeCalls{value: msg.value}(calls, desc);

        uint256 spentAmount = desc.amount;
        returnAmount = dstToken.universalBalanceOf(dstReceiver).sub(initialDstBalance);

        if (flags & _PARTIAL_FILL != 0) {
            spentAmount = initialSrcBalance.add(desc.amount).sub(srcToken.universalBalanceOf(msg.sender));
            require(returnAmount.mul(desc.amount) >= desc.minReturnAmount.mul(spentAmount), "Return amount is not enough");
        } else {
            require(returnAmount >= desc.minReturnAmount, "Return amount is not enough");
        }

        _emitSwapped(desc, srcToken, dstToken, dstReceiver, spentAmount, returnAmount);
    }

    function _emitSwapped(
        SwapDescription calldata desc,
        IERC20 srcToken,
        IERC20 dstToken,
        address dstReceiver,
        uint256 spentAmount,
        uint256 returnAmount
    ) private {
        emit Swapped(msg.sender, srcToken, dstToken, dstReceiver, desc.amount, spentAmount, returnAmount, desc.minReturnAmount);
    }

    function _claim(
        IERC20 token,
        address dst,
        uint256 amount,
        bytes calldata permit
    ) private {

        if (permit.length == 32 * 7) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory result) = address(token).call(abi.encodeWithSelector(IERC20Permit.permit.selector, permit));
            if (!success) {
                revert(RevertReasonParser.parse(result, "Permit call failed: "));
            }
        }

        token.safeTransferFrom(msg.sender, dst, amount);
    }

    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        token.universalTransfer(msg.sender, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }
}
