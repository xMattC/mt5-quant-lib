#include <MyLibs/Orders/CalculatePositionData.mqh>
#include <Trade/Trade.mqh>

class EntryOrders {
protected:
    CTrade trade;
    CalculatePositionData calc;

public:
    int count_open_positions(string symbol, int order_side, long _magic_number);

    bool open_buy_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode,
                         double tp_var, string _lot_mode, double lot_var, long _magic_number);

    bool open_sell_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode,
                          double tp_var, string _lot_mode, double lot_var, long _magic_number);

    bool open_buy_stop_order(string symbol, bool condition, double entry_price, datetime expiration, ENUM_TIMEFRAMES atr_period,
                             string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,
                             long _magic_number);

    bool open_sell_stop_order(string symbol, bool condition, double entry_price, datetime expiration, ENUM_TIMEFRAMES atr_period,
                              string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,
                              long _magic_number);

    bool open_runner_buy_order_with_virtual_tp(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var,
                                               string _tp_mode, double tp_var, string _lot_mode, double lot_var, long _magic_number);

    bool open_runner_sell_order_with_virtual_tp(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var,
                                                string _tp_mode, double tp_var, string _lot_mode, double lot_var, long _magic_number);
};

// ---------------------------------------------------------------------
// Counts open positions by symbol, side, and magic number.
//
// Parameters:
// - symbol        : Symbol to check.
// - order_side    : 1 = Buy, 2 = Sell, 0 = Any.
// - _magic_number : Magic number to filter.
//
// Returns:
// - Number of matching open positions.
// ---------------------------------------------------------------------
int EntryOrders::count_open_positions(string symbol, int order_side, long _magic_number) {
    int count = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == _magic_number) {
            int type = (int) PositionGetInteger(POSITION_TYPE);
            if (order_side == 0 || (order_side == 1 && type == POSITION_TYPE_BUY) || (order_side == 2 && type == POSITION_TYPE_SELL)) {
                count++;
            }
        }
    }
    return count;
}

// ---------------------------------------------------------------------
// Opens a market BUY position.
//
// Parameters:
// - symbol        : Symbol to trade.
// - condition     : If false, trade will not execute.
// - atr_period    : Timeframe for ATR-based SL/TP.
// - _sl_mode      : SL calculation method.
// - sl_var        : SL variable (e.g., pips or ATR multiplier).
// - _tp_mode      : TP calculation method.
// - tp_var        : TP variable.
// - _lot_mode     : Lot calculation method.
// - lot_var       : Lot sizing variable.
// - _magic_number : Magic number for trade.
//
// Returns:
// - True if trade was placed successfully.
// ---------------------------------------------------------------------
bool EntryOrders::open_buy_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var,
                                  string _tp_mode, double tp_var, string _lot_mode, double lot_var, long _magic_number) {
    if (!condition) return false;
    double current_price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    if (count_open_positions(symbol, 1, _magic_number) > 0) return false;

    double stop_loss = calc.calculate_stoploss(symbol, current_price, 1, _sl_mode, sl_var, atr_period);
    double take_profit = calc.calculate_take_profit(symbol, current_price, stop_loss, 1, _tp_mode, tp_var, atr_period);
    double sl_distance = current_price - stop_loss;
    double lots = calc.calculate_lots(symbol, sl_distance, current_price, _lot_mode, lot_var);

    if (lots <= 0) {
        Print("Lot calculation failed for ", symbol);
        return false;
    }

    trade.SetExpertMagicNumber(_magic_number);
    string comment = "Magic Number: " + IntegerToString(_magic_number);
    bool result = trade.PositionOpen(symbol, ORDER_TYPE_BUY, lots, current_price, stop_loss, take_profit, comment);
    if (!result) Print("Trade open failed for BUY ", symbol);
    return result;
}

// ---------------------------------------------------------------------
// Opens a market SELL position.
//
// Parameters:
// - symbol        : Symbol to trade.
// - condition     : If false, trade will not execute.
// - atr_period    : Timeframe for ATR-based SL/TP.
// - _sl_mode      : SL calculation method.
// - sl_var        : SL variable (e.g., pips or ATR multiplier).
// - _tp_mode      : TP calculation method.
// - tp_var        : TP variable.
// - _lot_mode     : Lot calculation method.
// - lot_var       : Lot sizing variable.
// - _magic_number : Magic number for trade.
//
// Returns:
// - True if trade was placed successfully.
// ---------------------------------------------------------------------
bool EntryOrders::open_sell_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var,
                                   string _tp_mode, double tp_var, string _lot_mode, double lot_var, long _magic_number) {
    if (!condition) return false;
    double current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
    if (count_open_positions(symbol, 2, _magic_number) > 0) return false;

    double stop_loss = calc.calculate_stoploss(symbol, current_price, 2, _sl_mode, sl_var, atr_period);
    double take_profit = calc.calculate_take_profit(symbol, current_price, stop_loss, 2, _tp_mode, tp_var, atr_period);
    double sl_distance = stop_loss - current_price;
    double lots = calc.calculate_lots(symbol, sl_distance, current_price, _lot_mode, lot_var);

    if (lots <= 0) {
        Print("Lot calculation failed for ", symbol);
        return false;
    }

    trade.SetExpertMagicNumber(_magic_number);
    string comment = "Magic Number: " + IntegerToString(_magic_number);
    bool result = trade.PositionOpen(symbol, ORDER_TYPE_SELL, lots, current_price, stop_loss, take_profit, comment);
    if (!result) Print("Trade open failed for SELL ", symbol);
    return result;
}

// ---------------------------------------------------------------------
// Opens a pending BUY STOP order.
//
// Parameters:
// - symbol        : Symbol to trade.
// - condition     : If false, order will not be placed.
// - entry_price   : Trigger price for Buy Stop.
// - expiration    : Expiration time for pending order.
// - atr_period    : Timeframe for ATR-based SL/TP.
// - _sl_mode      : SL calculation method.
// - sl_var        : SL variable.
// - _tp_mode      : TP calculation method.
// - tp_var        : TP variable.
// - _lot_mode     : Lot calculation method.
// - lot_var       : Lot sizing variable.
// - _magic_number : Magic number for order.
//
// Returns:
// - True if order was placed successfully.
// ---------------------------------------------------------------------
bool EntryOrders::open_buy_stop_order(string symbol, bool condition, double entry_price, datetime expiration, ENUM_TIMEFRAMES atr_period,
                                      string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,
                                      long _magic_number) {
    if (!condition) return false;
    if (count_open_positions(symbol, 1, _magic_number) > 0) return false;

    double stop_loss = calc.calculate_stoploss(symbol, entry_price, 1, _sl_mode, sl_var, atr_period);
    double take_profit = calc.calculate_take_profit(symbol, entry_price, stop_loss, 1, _tp_mode, tp_var, atr_period);
    double sl_distance = entry_price - stop_loss;
    double lots = calc.calculate_lots(symbol, sl_distance, entry_price, _lot_mode, lot_var);

    if (lots <= 0) {
        Print("Lot calculation failed for BUY STOP ", symbol);
        return false;
    }

    trade.SetExpertMagicNumber(_magic_number);
    string comment = "Magic Number: " + IntegerToString(_magic_number);
    bool result = trade.BuyStop(lots, entry_price, symbol, stop_loss, take_profit, ORDER_TIME_SPECIFIED, expiration, comment);
    if (!result) Print("BuyStop order failed for ", symbol);
    return result;
}

// ---------------------------------------------------------------------
// Opens a pending SELL STOP order.
//
// Parameters:
// - symbol        : Symbol to trade.
// - condition     : If false, order will not be placed.
// - entry_price   : Trigger price for Sell Stop.
// - expiration    : Expiration time for pending order.
// - atr_period    : Timeframe for ATR-based SL/TP.
// - _sl_mode      : SL calculation method.
// - sl_var        : SL variable.
// - _tp_mode      : TP calculation method.
// - tp_var        : TP variable.
// - _lot_mode     : Lot calculation method.
// - lot_var       : Lot sizing variable.
// - _magic_number : Magic number for order.
//
// Returns:
// - True if order was placed successfully.
// ---------------------------------------------------------------------
bool EntryOrders::open_sell_stop_order(string symbol, bool condition, double entry_price, datetime expiration, ENUM_TIMEFRAMES atr_period,
                                       string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,
                                       long _magic_number) {
    if (!condition) return false;
    if (count_open_positions(symbol, 2, _magic_number) > 0) return false;

    double stop_loss = calc.calculate_stoploss(symbol, entry_price, 2, _sl_mode, sl_var, atr_period);
    double take_profit = calc.calculate_take_profit(symbol, entry_price, stop_loss, 2, _tp_mode, tp_var, atr_period);
    double sl_distance = stop_loss - entry_price;
    double lots = calc.calculate_lots(symbol, sl_distance, entry_price, _lot_mode, lot_var);

    if (lots <= 0) {
        Print("Lot calculation failed for SELL STOP ", symbol);
        return false;
    }

    trade.SetExpertMagicNumber(_magic_number);
    string comment = "Magic Number: " + IntegerToString(_magic_number);
    bool result = trade.SellStop(lots, entry_price, symbol, stop_loss, take_profit, ORDER_TIME_SPECIFIED, expiration, comment);
    if (!result) Print("SellStop order failed for ", symbol);
    return result;
}

// ---------------------------------------------------------------------
// Opens a market BUY runner with virtual TP in comment.
//
// Parameters:
// - symbol        : Symbol to trade.
// - condition     : If false, trade will not execute.
// - atr_period    : Timeframe for ATR-based SL.
// - _sl_mode      : SL calculation method.
// - sl_var        : SL variable.
// - _tp_mode      : TP calculation method.
// - tp_var        : TP variable (used for virtual TP).
// - _lot_mode     : Lot calculation method.
// - lot_var       : Lot sizing variable.
// - _magic_number : Magic number for trade.
//
// Returns:
// - True if trade was placed successfully.
// ---------------------------------------------------------------------
bool EntryOrders::open_runner_buy_order_with_virtual_tp(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode,
                                                        double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,
                                                        long _magic_number) {
    if (!condition) return false;
    double current_price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    if (count_open_positions(symbol, 1, _magic_number) > 0) return false;

    double stop_loss = calc.calculate_stoploss(symbol, current_price, 1, _sl_mode, sl_var, atr_period);
    double virtual_tp = calc.calculate_take_profit(symbol, current_price, stop_loss, 1, _tp_mode, tp_var, atr_period);
    double sl_distance = current_price - stop_loss;
    double lots = calc.calculate_lots(symbol, sl_distance, current_price, _lot_mode, lot_var);

    if (lots <= 0) {
        Print("Lot calculation failed for runner BUY ", symbol);
        return false;
    }

    trade.SetExpertMagicNumber(_magic_number);
    string comment = StringFormat("runner_tp:%.5f", virtual_tp);
    bool result = trade.PositionOpen(symbol, ORDER_TYPE_BUY, lots, current_price, stop_loss, 0.0, comment);
    if (!result) Print("Runner BUY order failed for ", symbol);
    return result;
}

// ---------------------------------------------------------------------
// Opens a market SELL runner with virtual TP in comment.
//
// Parameters:
// - symbol        : Symbol to trade.
// - condition     : If false, trade will not execute.
// - atr_period    : Timeframe for ATR-based SL.
// - _sl_mode      : SL calculation method.
// - sl_var        : SL variable.
// - _tp_mode      : TP calculation method.
// - tp_var        : TP variable (used for virtual TP).
// - _lot_mode     : Lot calculation method.
// - lot_var       : Lot sizing variable.
// - _magic_number : Magic number for trade.
//
// Returns:
// - True if trade was placed successfully.
// ---------------------------------------------------------------------
bool EntryOrders::open_runner_sell_order_with_virtual_tp(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode,
                                                         double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,
                                                         long _magic_number) {
    if (!condition) return false;
    double current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
    if (count_open_positions(symbol, 2, _magic_number) > 0) return false;

    double stop_loss = calc.calculate_stoploss(symbol, current_price, 2, _sl_mode, sl_var, atr_period);
    double virtual_tp = calc.calculate_take_profit(symbol, current_price, stop_loss, 2, _tp_mode, tp_var, atr_period);
    double sl_distance = stop_loss - current_price;
    double lots = calc.calculate_lots(symbol, sl_distance, current_price, _lot_mode, lot_var);

    if (lots <= 0) {
        Print("Lot calculation failed for runner SELL ", symbol);
        return false;
    }

    trade.SetExpertMagicNumber(_magic_number);
    string comment = StringFormat("runner_tp:%.5f", virtual_tp);
    bool result = trade.PositionOpen(symbol, ORDER_TYPE_SELL, lots, current_price, stop_loss, 0.0, comment);
    if (!result) Print("Runner SELL order failed for ", symbol);
    return result;
}
