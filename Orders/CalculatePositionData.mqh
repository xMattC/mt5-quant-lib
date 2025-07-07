#include <MyLibs/Utils/MarketDataUtils.mqh>
#include <MyLibs/Utils/TimeZones.mqh>
#include <Trade/Trade.mqh>

class CalculatePositionData : public CObject {
   protected:
    CTrade trade;
    CPositionInfo position;
    MarketDataUtils mdu;

    bool check_lots(double& lots, string symbol);
    bool normalise_price(double price, double& normalizedPrice, string symbol);

   public:
    double calculate_stoploss(string symbol, double price, int order_side, string _sl_mode, double sl_var, ENUM_TIMEFRAMES atr_period);
    double calculate_take_profit(string symbol, double price, double stoploss, int order_side, string mode_tp, double tp_var,
                                 ENUM_TIMEFRAMES atr_period);
    double calculate_lots(string symbol, double sl_distance, double price, string mode_lot, double lot_var);
    double calculate_trading_cost(string symbol, ulong position_ticket);
};

double CalculatePositionData::calculate_stoploss(string symbol, double price, int order_side, string mode_sl, double sl_var,
                                                 ENUM_TIMEFRAMES atr_period) {
    // order_side int must be 1 for BUY or 2 for

    double sl = 0;

    if (mode_sl == "NO_STOPLOSS") {
        sl = 0;
    }

    if (mode_sl == "SL_BREAKEVEN") {
        // https://www.youtube.com/watch?v=idPulZ3_iR0
        Alert("Not implemented yet yet");
    }

    if (mode_sl == "SL_FIXED_PIPS") {
        // pips/poins = https://www.mql5.com/en/forum/187757
        double adj_point = mdu.adjusted_point(symbol);

        if (order_side == 1) {
            sl = price - sl_var * adj_point;
            if (!normalise_price(sl, sl, symbol)) {
                return false;
            }
        }
        if (order_side == 2) {
            sl = price + sl_var * adj_point;
            if (!normalise_price(sl, sl, symbol)) {
                return false;
            }
        }
    }

    if (mode_sl == "SL_FIXED_PERCENT") {
        if (order_side == 1) {
            sl = (-1.0 * sl_var * price / 100.00) + price;
            if (!normalise_price(sl, sl, symbol)) {
                return false;
            }
        }
        if (order_side == 2) {
            sl = sl_var * price / 100.00 + price;
            if (!normalise_price(sl, sl, symbol)) {
                return false;
            }
        }
    }

    if (mode_sl == "SL_ATR_MULTIPLE") {
        int _atr_handle = iATR(symbol, atr_period, 14);
        double atr[];
        ArraySetAsSeries(atr, true);
        CopyBuffer(_atr_handle, MAIN_LINE, 1, 1, atr);

        if (order_side == 1) {
            sl = price - (atr[0] * sl_var);
            if (!normalise_price(sl, sl, symbol)) {
                return false;
            }
        }
        if (order_side == 2) {
            sl = price + (atr[0] * sl_var);
            if (!normalise_price(sl, sl, symbol)) {
                return false;
            }
        }
    }

    if (mode_sl == "SL_SPECIFIED_VALUE") {
        double adj_point = mdu.adjusted_point(symbol);

        if (order_side == 1) {
            double pip_50_sl = price - 10 * adj_point;
            if (sl_var >= pip_50_sl) {
                sl = pip_50_sl;
            } else
                sl = sl_var;

            if (!normalise_price(sl, sl, symbol)) {
                return false;
            }
        }
        if (order_side == 2) {
            double pip_50_sl = price + 10 * adj_point;
            if (sl_var <= pip_50_sl) {
                sl = pip_50_sl;
            } else
                sl = sl_var;

            sl = sl = sl_var;
            if (!normalise_price(sl, sl, symbol)) {
                return false;
            }
        }
    }

    return sl;
}

double CalculatePositionData::calculate_take_profit(string symbol, double price, double stoploss, int order_side, string mode_tp,
                                                    double _tp_var, ENUM_TIMEFRAMES atr_period) {
    // order_side int must be 1 for BUY or 2 for SELL

    double tp = 0;

    if (mode_tp == "NO_TAKE_PROFIT") {
        tp = 0;
    }

    if (mode_tp == "TP_FIXED_PIPS") {
        double adj_point = mdu.adjusted_point(symbol);
        if (order_side == 1) {
            tp = price + _tp_var * adj_point;
            if (!normalise_price(tp, tp, symbol)) {
                return false;
            }
        }
        if (order_side == 2) {
            tp = price - _tp_var * adj_point;
            if (!normalise_price(tp, tp, symbol)) {
                return false;
            }
        }
    }

    if (mode_tp == "TP_FIXED_PERCENT") {
        if (order_side == 1) {
            tp = _tp_var * price / 100.00 + price;
            if (!normalise_price(tp, tp, symbol)) {
                return false;
            }
        }
        if (order_side == 2) {
            tp = (-1 * _tp_var * price / 100.00) + price;
            if (!normalise_price(tp, tp, symbol)) {
                return false;
            }
        }
    }

    if (mode_tp == "TP_ATR_MULTIPLE") {
        int _atr_handle = iATR(symbol, atr_period, 14);
        double atr[];
        ArraySetAsSeries(atr, true);
        CopyBuffer(_atr_handle, MAIN_LINE, 1, 1, atr);

        if (order_side == 1) {
            tp = price + (atr[0] * _tp_var);
            if (!normalise_price(tp, tp, symbol)) {
                return false;
            }
        }
        if (order_side == 2) {
            tp = price - (atr[0] * _tp_var);
            if (!normalise_price(tp, tp, symbol)) {
                return false;
            }
        }
    }

    if (mode_tp == "TP_SL_MULTIPLE") {
        if (order_side == 1) {
            double sl_size = price - stoploss;
            tp = price + (_tp_var * sl_size);
            if (!normalise_price(tp, tp, symbol)) {
                return false;
            }
        }
        if (order_side == 2) {
            double sl_size = stoploss - price;
            tp = price - (_tp_var * sl_size);
            if (!normalise_price(tp, tp, symbol)) {
                return false;
            }
        }
    }

    if (mode_tp == "TP_SPECIFIED_VALUE") {
        if (_tp_var != 0) {
            double adj_point = mdu.adjusted_point(symbol);

            if (order_side == 1) {
                double pip_limit = price + 10 * adj_point;
                if (_tp_var <= pip_limit) {
                    tp = pip_limit;
                } else
                    tp = _tp_var;

                if (!normalise_price(tp, tp, symbol)) {
                    return false;
                }
            }
            if (order_side == 2) {
                double pip_limit = price - 10 * adj_point;
                if (_tp_var >= pip_limit) {
                    tp = pip_limit;
                } else
                    tp = _tp_var;
                tp = tp = _tp_var;
                if (!normalise_price(tp, tp, symbol)) {
                    return false;
                }
            }
        }
    }
    return tp;
}

double CalculatePositionData::calculate_lots(string symbol, double sl_distance, double price, string mode_lot, double lot_var) {
    double lots = 0;
    double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double volume_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

    double account_value =
        fmin(fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)), AccountInfoDouble(ACCOUNT_MARGIN_FREE));
    double risk_money = account_value * lot_var / 100;

    if (mode_lot == "LOT_MODE_FIXED") {
        lots = lot_var;
    }

    if (mode_lot == "LOT_MODE_PCT_RISK") {
        double money_lot_step = (sl_distance / tick_size) * tick_value * volume_step;
        lots = MathFloor(risk_money / money_lot_step) * volume_step;
    }

    if (mode_lot == "LOT_MODE_PCT_ACCOUNT") {
        double money_lot_step = (price / tick_size) * tick_value * volume_step;
        lots = MathFloor(risk_money / money_lot_step) * volume_step;
    }

    if (!check_lots(lots, symbol)) {
        return false;
    }
    return lots;
}

bool CalculatePositionData::check_lots(double& lots, string symbol) {
    double min = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double max = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

    if (lots < min) {
        Print("Lot size will be set to minimum allowed volume");
        lots = min;
        return true;
    }

    if (lots > max) {
        Print("Lot size greater than maximum allowed volume. lots:", lots, "max:", max);
        return false;
    }

    lots = (int) MathFloor(lots / step) * step;
    return true;
}

bool CalculatePositionData::normalise_price(double price, double& normalizedPrice, string symbol) {
    double tickSize;
    if (!SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE, tickSize)) {
        Print("Failed to get tick size");
        return false;
    }
    int symbol_digits = (int) SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    normalizedPrice = NormalizeDouble(MathRound(price / tickSize) * tickSize, symbol_digits);
    return true;
}

double CalculatePositionData::calculate_trading_cost(string symbol, ulong position_ticket) {
    position.SelectByTicket(position_ticket);

    double swap = PositionGetDouble(POSITION_SWAP);
    double commission = PositionGetDouble(POSITION_COMMISSION);
    double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double lot_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    double lots = PositionGetDouble(POSITION_VOLUME);
    double trading_cost = -1 * ((commission + swap) / tick_value * tick_size / lots);

    return trading_cost;
}