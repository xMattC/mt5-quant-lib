#include <MyLibs/Orders/CalculatePositionData.mqh>
#include <MyLibs/Utils/TimeZones.mqh>
#include <Trade/Trade.mqh>

class ExitOrders {
protected:
    CTrade trade;
    TimeZones tz;
    CalculatePositionData calc;

    ulong posTicket;
    long position_open_time;
    long first_allowed_close_time;

public:
    bool close_buy_orders(string symbol, bool condition, int close_bars, ENUM_TIMEFRAMES close_bar_period, long _magic_number);
    bool close_sell_orders(string symbol, bool condition, int close_bars, ENUM_TIMEFRAMES close_bar_period, long _magic_number);
    bool daily_timed_exit(string symbol, datetime exit_time, int delay_days, long _magic_number);
    bool daily_timed_profit_exit(string symbol, ENUM_TIMEFRAMES close_bar_period, string exit_time, string cw_tzone, int delay_days, long _magic_number);
    bool first_profitable_close_exit(string symbol, ENUM_TIMEFRAMES close_bar_period, long _magic_number);
};

// ---------------------------------------------------------------------
// Closes BUY positions on condition + after a number of bars (if non 0) .
//
// Parameters:
// - symbol           : Symbol to evaluate positions for.
// - condition        : If true, closes position immediately.
// - close_bars       : Minimum number of bars before auto close.
// - close_bar_period : Timeframe to count bars on.
// - _magic_number    : Magic number to identify the trade group.
//
// Returns:
// - True after evaluation and any attempted closes.
// ---------------------------------------------------------------------
bool ExitOrders::close_buy_orders(string symbol, bool condition, int close_bars, ENUM_TIMEFRAMES close_bar_period, long _magic_number) {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        posTicket = PositionGetTicket(i);

        if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == _magic_number) {
            int time_difference = Bars(symbol, close_bar_period, PositionGetInteger(POSITION_TIME), TimeCurrent()) - 1;

            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                if (condition || (close_bars > 0 && time_difference >= close_bars)) {
                    trade.PositionClose(posTicket);
                }
            }
        }
    }
    return true;
}

// ---------------------------------------------------------------------
// Closes SELL positions on condition + after a number of bars (if non 0) .
//
// Parameters:
// - symbol           : Symbol to evaluate positions for.
// - condition        : If true, closes position immediately.
// - close_bars       : Minimum number of bars before auto close.
// - close_bar_period : Timeframe to count bars on.
// - _magic_number    : Magic number to identify the trade group.
//
// Returns:
// - True after evaluation and any attempted closes.
// ---------------------------------------------------------------------
bool ExitOrders::close_sell_orders(string symbol, bool condition, int close_bars, ENUM_TIMEFRAMES close_bar_period, long _magic_number) {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        posTicket = PositionGetTicket(i);

        if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == _magic_number) {
            int time_difference = Bars(symbol, close_bar_period, PositionGetInteger(POSITION_TIME), TimeCurrent()) - 1;

            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                if (condition || (close_bars > 0 && time_difference >= close_bars)) {
                    trade.PositionClose(posTicket);
                }
            }
        }
    }
    return true;
}

// ---------------------------------------------------------------------
// Closes position after a fixed exit time and delay in days.
//
// Parameters:
// - symbol           : Symbol to evaluate.
// - exit_time        : Time of day when exit is permitted.
// - delay_days       : Number of full days before close allowed.
// - _magic_number    : Magic number to identify the trade group.
//
// Returns:
// - True after evaluation and any attempted closes.
// ---------------------------------------------------------------------
bool ExitOrders::daily_timed_exit(string symbol, datetime exit_time, int delay_days, long _magic_number) {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        posTicket = PositionGetTicket(i);
        position_open_time = PositionGetInteger(POSITION_TIME);

        if ((int) position_open_time > 0) {
            first_allowed_close_time = position_open_time + (delay_days * PeriodSeconds(PERIOD_D1));

            if (TimeCurrent() > first_allowed_close_time && TimeCurrent() >= exit_time) {
                if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == _magic_number) {
                    trade.PositionClose(posTicket);
                }
            }
        }
    }
    return true;
}

// ---------------------------------------------------------------------
// Closes a position only if it's profitable after a given time.
//
// Parameters:
// - symbol           : Symbol to evaluate.
// - close_bar_period : Bar timeframe for bar-close evaluation.
// - exit_time        : Time of day when profit exit is checked.
// - cw_tzone         : Clockwork time zone for exit conversion.
// - delay_days       : Minimum days to wait before closing.
// - _magic_number    : Magic number to identify the trade group.
//
// Returns:
// - True after evaluation and any attempted closes.
// ---------------------------------------------------------------------
bool ExitOrders::daily_timed_profit_exit(string symbol, ENUM_TIMEFRAMES close_bar_period, string exit_time, string cw_tzone, int delay_days,
                                         long _magic_number) {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        posTicket = PositionGetTicket(i);
        position_open_time = PositionGetInteger(POSITION_TIME);

        if ((int) position_open_time > 0) {
            first_allowed_close_time = position_open_time + (delay_days * PeriodSeconds(PERIOD_D1));

            if (TimeCurrent() > first_allowed_close_time) {
                datetime broker_close_time = tz.timezone_conversions(cw_tzone, StringToTime(exit_time), "Broker");

                if (TimeCurrent() >= broker_close_time && PositionGetString(POSITION_SYMBOL) == symbol &&
                    PositionGetInteger(POSITION_MAGIC) == _magic_number) {
                    double position_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
                    double spread = SymbolInfoDouble(symbol, SYMBOL_ASK) - SymbolInfoDouble(symbol, SYMBOL_BID);
                    double bar_close = iClose(_Symbol, close_bar_period, 1);  // shift 1 because 0 is live candle
                    double trading_cost = calc.calculate_trading_cost(symbol, posTicket);

                    if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY &&
                        bar_close > (position_open_price + spread + trading_cost)) {
                        trade.PositionClose(posTicket);
                    }

                    if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL &&
                        bar_close < (position_open_price - spread - trading_cost)) {
                        trade.PositionClose(posTicket);
                    }
                }
            }
        }
    }
    return true;
}

// ---------------------------------------------------------------------
// Closes position on first profitable bar after one bar completes.
//
// Parameters:
// - symbol           : Symbol to evaluate.
// - close_bar_period : Timeframe for bar-close evaluation.
// - _magic_number    : Magic number to identify the trade group.
//
// Returns:
// - True after evaluation and any attempted closes.
// ---------------------------------------------------------------------
bool ExitOrders::first_profitable_close_exit(string symbol, ENUM_TIMEFRAMES close_bar_period, long _magic_number) {
    position_open_time = PositionGetInteger(POSITION_TIME);
    first_allowed_close_time = position_open_time + PeriodSeconds(close_bar_period);

    if ((int) position_open_time > 0 && TimeCurrent() > first_allowed_close_time) {
        for (int i = PositionsTotal() - 1; i >= 0; i--) {
            posTicket = PositionGetTicket(i);

            if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == _magic_number) {
                double position_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
                double spread = SymbolInfoDouble(symbol, SYMBOL_ASK) - SymbolInfoDouble(symbol, SYMBOL_BID);
                double bar_close = iClose(_Symbol, close_bar_period, 1);
                double trading_cost = calc.calculate_trading_cost(symbol, posTicket);

                if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && bar_close > (position_open_price + spread + trading_cost)) {
                    trade.PositionClose(posTicket);
                }

                if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && bar_close < (position_open_price - spread - trading_cost)) {
                    trade.PositionClose(posTicket);
                }
            }
        }
    }

    return true;
}
