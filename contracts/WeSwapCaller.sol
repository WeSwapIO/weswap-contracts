// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IWeSwapCaller.sol";
import "./callers/DistributionCaller.sol";
import "./callers/SafeERC20Extension.sol";
import "./callers/UniswapCaller.sol";
import "./callers/DMMCaller.sol";
import "./callers/SolidlyCaller.sol";
import "./libraries/CallDescriptions.sol";

contract WeSwapCaller is IWeSwapCaller, DistributionCaller, SafeERC20Extension, UniswapV2LikeCaller, UniswapV3Caller, DMMCaller, SolidlyCaller {
    using CallDescriptions for CallDescription;
    using SafeMath for uint256;

    receive() external payable {
        // cannot directly send eth to this contract
        require(msg.sender != tx.origin);
    }

    function makeCall(CallDescription memory desc) external override {
        (bool success, string memory errorMessage) = desc.execute();
        if (!success) {
            revert(errorMessage);
        }
    }

    function makeCalls(CallDescription[] memory desc, SwapDescription calldata swapDesc) external payable override {
        require(desc.length > 0, "WeSwap: Invalid call parameter");
        for (uint256 i = 0; i < desc.length; i++) {
            CallDescription memory tempDesc = desc[i];

            if (tempDesc.swapped) {
                require(swapDesc.estimateOutAmount > 0, "WeSwap: Invalid param");
                require(swapDesc.feeReceiver != address(0), "WeSwap: Fee address should not be zero");
                uint256 balance = swapDesc.dstToken.universalBalanceOf(address(this));
                if (balance > swapDesc.estimateOutAmount) {
                    swapDesc.dstToken.universalTransfer(payable(swapDesc.feeReceiver), balance.sub(swapDesc.estimateOutAmount));
                }
            }

            this.makeCall(tempDesc);
        }
    }
}
