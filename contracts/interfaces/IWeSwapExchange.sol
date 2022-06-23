// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWeSwapExchange {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        address feeReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 estimateOutAmount;
        uint256 flags;
        bytes permit;
    }
}
