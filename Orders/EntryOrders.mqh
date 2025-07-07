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

    bool open_buy_stop_order(string symbol, bool condition, double entry_price, datetime experation, ENUM_TIMEFRAMES atr_period,
                             string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,
                             long _magic_number);

    bool open_sell_stop_order(string symbol, bool condition, double entry_price, datetime experation, ENUM_TIMEFRAMES atr_period,
                              string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,
                              long _magic_number);

    bool open_runner_buy_order_with_virtual_tp(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var,
                                               string _tp_mode, double tp_var, string _lot_mode, double lot_var, long _magic_number);

    bool open_runner_sell_order_with_virtual_tp(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var,
                                                string _tp_mode, double tp_var, string _lot_mode, double lot_var, long _magic_number);
};

int EntryOrders::count_open_positions(string symbol, int order_side, long _magic_number) {
    int count = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == _magic_number) {
            int type = (int) PositionGetInteger(POSITION_TYPE);

            // Count: order_side == 0 (both sides), order_side == 1 (longs only), order_side == 2 (shorts only)
            if (order_side == 0 || (order_side == 1 && type == POSITION_TYPE_BUY) || (order_side == 2 && type == POSITION_TYPE_SELL)) {
                count++;
            }
        }
    }
    return count;
}

bool EntryOrders::open_buy_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var,
                                  string _tp_mode, double tp_var, string _lot_mode, double lot_var, long _magic_number) {
    if (!condition) return false;

    double current_price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    if (count_open_positions(symbol, 1, _magic_number) > 0) return false;

    double stop_loss = calc.calculate_stoploss(symbol, current_price, 1, _sl_mode, sl_var, atr_period);
    double take_profit = calc.calculate_take_profit(symbol, current_price, stop_loss, 1, _tp_mode, tp_var, atr_period);
    double sl_distance = current_price - stop_loss;
    double lots = calc.calculate_lots(symbol, sl_distance, current_price, _lot_mode, lot_var);

    trade.SetExpertMagicNumber(_magic_number);
    string comment = "Magic Number: " + IntegerToString(_magic_number);
    return trade.PositionOpen(symbol, ORDER_TYPE_BUY, lots, current_price, stop_loss, take_profit, comment);
}

bool EntryOrders::open_sell_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var,
                                   string _tp_mode, double tp_var, string _lot_mode, double lot_var, long _magic_number) {
    if (!condition) return false;

    double current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
    if (count_open_positions(symbol, 2, _magic_number) > 0) return false;

    double stop_loss = calc.calculate_stoploss(symbol, current_price, 2, _sl_mode, sl_var, atr_period);
    double take_profit = calc.calculate_take_profit(symbol, current_price, stop_loss, 2, _tp_mode, tp_var, atr_period);
    double sl_distance = stop_loss - current_price;
    double lots = calc.calculate_lots(symbol, sl_distance, current_price, _lot_mode, lot_var);

    trade.SetExpertMagicNumber(_magic_number);
    string comment = "Magic Number: " + IntegerToString(_magic_number);
    return trade.PositionOpen(symbol, ORDER_TYPE_SELL, lots, current_price, stop_loss, take_profit, comment);
}

bool EntryOrders::open_buy_stop_order(string symbol, bool condition, double entry_price, datetime experation, ENUM_TIMEFRAMES atr_period,
                                      string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,
                                      long _magic_number) {
    if (!condition) return false;
    if (count_open_positions(symbol, 1, _magic_number) > 0) return false;

    double stop_loss = calc.calculate_stoploss(symbol, entry_price, 1, _sl_mode, sl_var, atr_period);
    double take_profit = calc.calculate_take_profit(symbol, entry_price, stop_loss, 1, _tp_mode, tp_var, atr_period);
    double sl_distance = entry_price - stop_loss;
    double lots = calc.calculate_lots(symbol, sl_distance, entry_price, _lot_mode, lot_var);

    trade.SetExpertMagicNumber(_magic_number);
    string comment = "Magic Number: " + IntegerToString(_magic_number);
    return trade.BuyStop(lots, entry_price, symbol, stop_loss, take_profit, ORDER_TIME_SPECIFIED, experation, comment);
}

bool EntryOrders::open_sell_stop_order(string symbol, bool condition, double entry_price, datetime experation, ENUM_TIMEFRAMES atr_period,
                                       string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,
                                       long _magic_number) {
    if (!condition) return false;
    if (count_open_positions(symbol, 2, _magic_number) > 0) return false;

    double stop_loss = calc.calculate_stoploss(symbol, entry_price, 2, _sl_mode, sl_var, atr_period);
    double take_profit = calc.calculate_take_profit(symbol, entry_price, stop_loss, 2, _tp_mode, tp_var, atr_period);
    double sl_distance = stop_loss - entry_price;
    double lots = calc.calculate_lots(symbol, sl_distance, entry_price, _lot_mode, lot_var);

    trade.SetExpertMagicNumber(_magic_number);
    string comment = "Magic Number: " + IntegerToString(_magic_number);
    return trade.SellStop(lots, entry_price, symbol, stop_loss, take_profit, ORDER_TIME_SPECIFIED, experation, comment);
}

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

    trade.SetExpertMagicNumber(_magic_number);
    string comment = StringFormat("runner_tp:%.5f", virtual_tp);
    return trade.PositionOpen(symbol, ORDER_TYPE_BUY, lots, current_price, stop_loss, 0.0, comment);
}

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

    trade.SetExpertMagicNumber(_magic_number);
    string comment = StringFormat("runner_tp:%.5f", virtual_tp);
    return trade.PositionOpen(symbol, ORDER_TYPE_SELL, lots, current_price, stop_loss, 0.0, comment);
}
