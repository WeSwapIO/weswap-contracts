// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/ISolidlyCaller.sol";

abstract contract SolidlyCaller is ISolidlyCaller {
    using SafeMath for uint256;

    uint256 private constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant REVERSE_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;

    function solidlySwap(
        uint256 pool,
        address srcToken,
        address receiver
    ) external override {
        address pair = address(pool & ADDRESS_MASK);
        bool reverse = (pool & REVERSE_MASK) != 0;

        uint256 inReserve;
        {
            // avoid stack too deep error
            (, , uint256 reserve0, uint256 reserve1, , , ) = ISolidlyPair(pair).metadata();
            inReserve = reverse ? reserve1 : reserve0;
        }

        uint256 inAmount = IERC20(srcToken).balanceOf(pair).sub(inReserve);
        require(inAmount > 0, "WeSwap: INSUFFICIENT_INPUT_AMOUNT");
        uint256 outAmount = calculateOutAmount(pair, inAmount, reverse);

        (uint256 amount0Out, uint256 amount1Out) = reverse ? (outAmount, uint256(0)) : (uint256(0), outAmount);
        ISolidlyPair(pair).swap(amount0Out, amount1Out, receiver, new bytes(0));
    }

    function _f(uint256 x0, uint256 y) private pure returns (uint256) {
        uint256 part1 = (x0.mul(((((y.mul(y)).div(1e18)).mul(y)).div(1e18)))).div(1e18);
        uint256 part2_1 = x0.mul(x0);
        uint256 part2 = (((((part2_1).div(1e18)).mul(x0)).div(1e18)).mul(y)).div(1e18);
        return part1.add(part2);
    }

    function _d(uint256 x0, uint256 y) private pure returns (uint256) {
        uint256 part1 = (x0.mul(3).mul((y.mul(y).div(1e18)))).div(1e18);
        uint256 part2 = (((x0.mul(x0)).div(1e18)).mul(x0)).div(1e18);
        return part1.add(part2);
    }

    function _get_y(
        uint256 x0,
        uint256 xy,
        uint256 y
    ) private pure returns (uint256) {
        for (uint256 i = 0; i < 255; i++) {
            uint256 y_prev = y;
            uint256 k = _f(x0, y);
            if (k < xy) {
                uint256 dy = ((xy.sub(k)).mul(1e18)).div(_d(x0, y));
                y = y.add(dy);
            } else {
                uint256 dy = ((k.sub(xy)).mul(1e18)).div(_d(x0, y));
                y = y.sub(dy);
            }
            if (y > y_prev) {
                if (y.sub(y_prev) <= 1) {
                    return y;
                }
            } else {
                if (y_prev.sub(y) <= 1) {
                    return y;
                }
            }
        }
        return y;
    }

    function _k(
        uint256 x,
        uint256 y,
        uint256 decimals0,
        uint256 decimals1,
        bool stable
    ) private pure returns (uint256) {
        if (stable) {
            uint256 _x = (x.mul(1e18)).div(decimals0);
            uint256 _y = (y.mul(1e18)).div(decimals1);
            uint256 _a = (_x.mul(_y)).div(1e18);
            uint256 _b = ((_x.mul(_x)).div(1e18)).add((_y.mul(_y)).div(1e18));
            return (_a.mul(_b)).div(1e18); // x3y+y3x >= k
        } else {
            return x.mul(y); // xy >= k
        }
    }

    function calculateOutAmount(
        address pair,
        uint256 amount,
        bool reverse
    ) internal view returns (uint256) {
        amount = amount.sub(amount.div(10000));
        (uint256 decimals0, uint256 decimals1, uint256 reserve0, uint256 reserve1, bool stable, , ) = ISolidlyPair(pair).metadata();
        if (stable) {
            uint256 xy = _k(reserve0, reserve1, decimals0, decimals1, stable);
            reserve0 = (reserve0.mul(1e18)).div(decimals0);
            reserve1 = (reserve1.mul(1e18)).div(decimals1);
            (uint256 reserveA, uint256 reserveB) = reverse ? (reserve1, reserve0) : (reserve0, reserve1);
            amount = reverse ? (amount.mul(1e18)).div(decimals1) : (amount.mul(1e18)).div(decimals0);
            uint256 y = reserveB.sub(_get_y(amount.add(reserveA), xy, reserveB));
            return (y.mul((reverse ? decimals0 : decimals1))).div(1e18);
        } else {
            (uint256 reserveA, uint256 reserveB) = reverse ? (reserve1, reserve0) : (reserve0, reserve1);
            return (amount.mul(reserveB)).div((reserveA.add(amount)));
        }
    }
}
