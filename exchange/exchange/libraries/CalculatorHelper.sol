// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { Order, Side } from "../libraries/OrderStructs.sol";

library CalculatorHelper {
    uint256 internal constant ONE = 10 ** 18;

    uint256 internal constant BPS_DIVISOR = 10_000;

    function calculateTakingAmount(uint256 makingAmount, uint256 makerAmount, uint256 takerAmount)
        internal
        pure
        returns (uint256)
    {
        if (makerAmount == 0) return 0;
        return makingAmount * takerAmount / makerAmount;
    }


    function calculateFee(
        uint256 feeRateBps,
        uint256 outcomeTokens,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side
    ) internal pure returns (uint256 fee) {
        if (feeRateBps > 0) {
            uint256 price = _calculatePrice(makerAmount, takerAmount, side);
            if (price > 0 && price <= ONE) {
                if (side == Side.BUY) {
                    // Fee charged on Token Proceeds:
                    // baseRate * min(price, 1-price) * (outcomeTokens/price)
                    fee = (feeRateBps * min(price, ONE - price) * outcomeTokens) / (price * BPS_DIVISOR);
                } else {
                    // Fee charged on Collateral proceeds:
                    // baseRate * min(price, 1-price) * outcomeTokens
                    fee = feeRateBps * min(price, ONE - price) * outcomeTokens / (BPS_DIVISOR * ONE);
                }
            }
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function calculatePrice(Order memory order) internal pure returns (uint256) {
        return _calculatePrice(order.makerAmount, order.takerAmount, order.side);
    }

    function _calculatePrice(uint256 makerAmount, uint256 takerAmount, Side side) internal pure returns (uint256) {
        if (side == Side.BUY) return takerAmount != 0 ? makerAmount * ONE / takerAmount : 0;
        return makerAmount != 0 ? takerAmount * ONE / makerAmount : 0;
    }

    function isCrossing(Order memory a, Order memory b) internal pure returns (bool) {
        if (a.takerAmount == 0 || b.takerAmount == 0) return true;

        return _isCrossing(calculatePrice(a), calculatePrice(b), a.side, b.side);
    }

    function _isCrossing(uint256 priceA, uint256 priceB, Side sideA, Side sideB) internal pure returns (bool) {
        if (sideA == Side.BUY) {
            if (sideB == Side.BUY) {
                // if a and b are bids
                return priceA + priceB >= ONE;
            }
            // if a is bid and b is ask
            return priceA >= priceB;
        }
        if (sideB == Side.BUY) {
            // if a is ask and b is bid
            return priceB >= priceA;
        }
        // if a and b are asks
        return priceA + priceB <= ONE;
    }
}
