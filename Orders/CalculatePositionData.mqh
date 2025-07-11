#include <MyLibs/Utils/MarketDataUtils.mqh>
#include <MyLibs/Utils/TimeZones.mqh>
#include <MyLibs/Utils/AtrHandleManager.mqh>
#include <Trade/Trade.mqh>

class CalculatePositionData : public CObject {
protected:
    CTrade trade;
    CPositionInfo position;
    MarketDataUtils mdu;
    AtrHandleManager atr_manager;

    bool check_lots(double& lots, string symbol);
    bool normalise_price(double price, double& normalizedPrice, string symbol);

public:
    double calculate_stoploss(string symbol, double price, int order_side, string mode_sl, double sl_var, ENUM_TIMEFRAMES atr_tf);
    double calculate_take_profit(string symbol, double price, double stoploss, int order_side, string mode_tp, double tp_var, ENUM_TIMEFRAMES atr_tf);
    double calculate_lots(string symbol, double sl_distance, double price, string mode_lot, double lot_var);
    double calculate_trading_cost(string symbol, ulong ticket);
};

//+------------------------------------------------------------------+

double CalculatePositionData::calculate_stoploss(string symbol, double price, int order_side, string mode_sl, double sl_var, ENUM_TIMEFRAMES atr_tf) {
    double sl = 0;

    if (mode_sl == "NO_STOPLOSS") return 0;

    if (mode_sl == "SL_FIXED_PIPS") {
        double adj_point = mdu.adjusted_point(symbol);
        sl = (order_side == 1) ? price - sl_var * adj_point : price + sl_var * adj_point;
        if (!normalise_price(sl, sl, symbol)) return 0;
    }

    if (mode_sl == "SL_FIXED_PERCENT") {
        sl = (order_side == 1) ? price - (sl_var * price / 100.0) : price + (sl_var * price / 100.0);
        if (!normalise_price(sl, sl, symbol)) return 0;
    }

    if (mode_sl == "SL_ATR_MULTIPLE") {
        double atr = atr_manager.get_atr_value(symbol, atr_tf, 14);
        if (atr == EMPTY_VALUE) return 0;
        sl = (order_side == 1) ? price - atr * sl_var : price + atr * sl_var;
        if (!normalise_price(sl, sl, symbol)) return 0;
    }

    if (mode_sl == "SL_SPECIFIED_VALUE") {
        double adj_point = mdu.adjusted_point(symbol);
        double limit_sl = (order_side == 1) ? price - 10 * adj_point : price + 10 * adj_point;
        sl = (order_side == 1) ? fmax(sl_var, limit_sl) : fmin(sl_var, limit_sl);
        if (!normalise_price(sl, sl, symbol)) return 0;
    }

    return sl;
}

//+------------------------------------------------------------------+

double CalculatePositionData::calculate_take_profit(string symbol, double price, double stoploss, int order_side, string mode_tp, double tp_var, ENUM_TIMEFRAMES atr_tf) {
    double tp = 0;

    if (mode_tp == "NO_TAKE_PROFIT") return 0;

    if (mode_tp == "TP_FIXED_PIPS") {
        double adj_point = mdu.adjusted_point(symbol);
        tp = (order_side == 1) ? price + tp_var * adj_point : price - tp_var * adj_point;
        if (!normalise_price(tp, tp, symbol)) return 0;
    }

    if (mode_tp == "TP_FIXED_PERCENT") {
        tp = (order_side == 1) ? price + tp_var * price / 100.0 : price - tp_var * price / 100.0;
        if (!normalise_price(tp, tp, symbol)) return 0;
    }

    if (mode_tp == "TP_ATR_MULTIPLE") {
        double atr = atr_manager.get_atr_value(symbol, atr_tf, 14);
        if (atr == EMPTY_VALUE) return 0;
        tp = (order_side == 1) ? price + atr * tp_var : price - atr * tp_var;
        if (!normalise_price(tp, tp, symbol)) return 0;
    }

    if (mode_tp == "TP_SL_MULTIPLE") {
        double sl_size = (order_side == 1) ? price - stoploss : stoploss - price;
        tp = (order_side == 1) ? price + tp_var * sl_size : price - tp_var * sl_size;
        if (!normalise_price(tp, tp, symbol)) return 0;
    }

    if (mode_tp == "TP_SPECIFIED_VALUE") {
        double adj_point = mdu.adjusted_point(symbol);
        double limit_tp = (order_side == 1) ? price + 10 * adj_point : price - 10 * adj_point;
        tp = (order_side == 1) ? fmin(tp_var, limit_tp) : fmax(tp_var, limit_tp);
        if (!normalise_price(tp, tp, symbol)) return 0;
    }

    return tp;
}

//+------------------------------------------------------------------+

double CalculatePositionData::calculate_lots(string symbol, double sl_distance, double price, string mode_lot, double lot_var) {
    double lots = 0;
    double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double volume_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

    double account_value = fmin(fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)), AccountInfoDouble(ACCOUNT_MARGIN_FREE));
    double risk_money = account_value * lot_var / 100.0;

    if (mode_lot == "LOT_MODE_FIXED") {
        lots = lot_var;
    }

    if (mode_lot == "LOT_MODE_PCT_RISK") {
        double money_per_step = (sl_distance / tick_size) * tick_value * volume_step;
        lots = MathFloor(risk_money / money_per_step) * volume_step;
    }

    if (mode_lot == "LOT_MODE_PCT_ACCOUNT") {
        double money_per_step = (price / tick_size) * tick_value * volume_step;
        lots = MathFloor(risk_money / money_per_step) * volume_step;
    }

    if (!check_lots(lots, symbol)) return 0;
    return lots;
}

//+------------------------------------------------------------------+

bool CalculatePositionData::check_lots(double& lots, string symbol) {
    double min = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double max = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

    if (lots < min) {
        lots = min;
        return true;
    }

    if (lots > max) {
        Print("Lot size exceeds max for ", symbol);
        return false;
    }

    lots = (int)MathFloor(lots / step) * step;
    return true;
}

//+------------------------------------------------------------------+

bool CalculatePositionData::normalise_price(double price, double& normalizedPrice, string symbol) {
    double tick_size;
    if (!SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE, tick_size)) {
        Print("Failed to get tick size for ", symbol);
        return false;
    }

    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    normalizedPrice = NormalizeDouble(MathRound(price / tick_size) * tick_size, digits);
    return true;
}

//+------------------------------------------------------------------+

// double CalculatePositionData::calculate_trading_cost(string symbol, ulong ticket) {
//     position.SelectByTicket(ticket);

//     double swap = PositionGetDouble(POSITION_SWAP);
//     double commission = PositionGetDouble(POSITION_COMMISSION);
//     double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
//     double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
//     double lots = PositionGetDouble(POSITION_VOLUME);

//     return -1.0 * ((commission + swap) / tick_value * tick_size / lots);
// }
