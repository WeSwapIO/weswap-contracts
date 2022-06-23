// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IWeSwapExchange.sol";

interface IWeSwapCaller is IWeSwapExchange {
    struct CallDescription {
        uint256 target;
        uint256 gasLimit;
        uint256 value;
        bool swapped;
        bytes data;
    }

    function makeCall(CallDescription memory desc) external;

    function makeCalls(CallDescription[] memory desc, SwapDescription calldata swapDesc) external payable;
}
