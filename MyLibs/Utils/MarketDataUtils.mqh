class MarketDataUtils {
    public:
        bool is_new_bar(string symbol, ENUM_TIMEFRAMES time_frame, string daily_start_time = "00:10");
        double get_latest_buffer_value(int handle);
        double get_buffer_value(int handle, int shift);
        double adjusted_point(string symbol);
        double get_bid_ask_price(string symbol, int price_side);

    protected:
        datetime previousTimes[];  // Stores last recorded open time per key
        string bar_keys[];         // Keys are symbol+TF combinations, e.g. "EURUSD_PERIOD_H1"
};

// ---------------------------------------------------------------------
// Performs linear search on a string array.
//
// Parameters:
// - arr    : Array of strings.
// - target : Target string to find.
//
// Returns:
// - Index of the target, or -1 if not found.
// ---------------------------------------------------------------------
int LinearSearch(string& arr[], string target) {
    for (int i = 0; i < ArraySize(arr); i++) {
        if (arr[i] == target) return i;
    }
    return -1;
}

// ---------------------------------------------------------------------
// Implementation of is_new_bar. Tracks the open time of the last bar.
//
// Parameters:
// - symbol          : Symbol to check.
// - time_frame      : Timeframe to check.
// - daily_start_time: Time string for daily bar sync.
//
// Returns:
// - true if a new bar has formed, false otherwise.
// ---------------------------------------------------------------------
bool MarketDataUtils::is_new_bar(string symbol, ENUM_TIMEFRAMES time_frame, string daily_start_time) {
    datetime bar_open_time = iTime(symbol, time_frame, 0);  // Current open time
    string key = symbol + "_" + EnumToString(time_frame);

    int idx = LinearSearch(bar_keys, key);
    if (idx == -1) {
        int new_size = ArraySize(bar_keys) + 1;
        ArrayResize(bar_keys, new_size);
        ArrayResize(previousTimes, new_size);

        idx = new_size - 1;
        bar_keys[idx] = key;
        previousTimes[idx] = 0;
    }

    if (previousTimes[idx] != bar_open_time) {
        if (PeriodSeconds(time_frame) == PeriodSeconds(PERIOD_D1)) {
            if (TimeCurrent() > StringToTime(daily_start_time)) {
                previousTimes[idx] = bar_open_time;
                return true;
            }
        } else {
            previousTimes[idx] = bar_open_time;
            return true;
        }
    }

    return false;
}

// ---------------------------------------------------------------------
// Implementation of get_buffer_value.
//
// Parameters:
// - handle : Indicator handle.
// - shift  : Shift index for historical bars.
//
// Returns:
// - The buffer value, or EMPTY_VALUE if error.
// ---------------------------------------------------------------------
double MarketDataUtils::get_buffer_value(int handle, int shift) {
    double val[];
    ArraySetAsSeries(val, true);

    int copied = CopyBuffer(handle, 0, shift, 1, val);
    if (copied <= 0) {
        Print("CopyBuffer failed: handle=", handle, " shift=", shift);
        return EMPTY_VALUE;
    }

    if (val[0] == EMPTY_VALUE) {
        Print("EMPTY_VALUE returned for buffer at shift=", shift);
        return EMPTY_VALUE;
    }

    return val[0];
}

// ---------------------------------------------------------------------
// Gets the latest (live) value from buffer (shift = 0).
//
// Parameters:
// - handle : Indicator handle.
//
// Returns:
// - Buffer value at shift 0 or EMPTY_VALUE if failed.
// ---------------------------------------------------------------------
double MarketDataUtils::get_latest_buffer_value(int handle) {
    return get_buffer_value(handle, 0);
}

// ---------------------------------------------------------------------
// Computes adjusted point value considering fractional pip brokers.
//
// Parameters:
// - symbol : Symbol name.
//
// Returns:
// - Adjusted point multiplier.
// ---------------------------------------------------------------------
double MarketDataUtils::adjusted_point(string symbol) {
    int symbol_digits = (int) SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    int digits_adjust = (symbol_digits == 3 || symbol_digits == 5) ? 10 : 1;
    double point_val = SymbolInfoDouble(symbol, SYMBOL_POINT);
    return point_val * digits_adjust;
}

// ---------------------------------------------------------------------
// Returns bid or ask price for a given symbol.
//
// Parameters:
// - symbol     : Symbol name.
// - price_side : 1 = Ask, 2 = Bid.
//
// Returns:
// - Price value or 0.0 if input is invalid.
// ---------------------------------------------------------------------
double MarketDataUtils::get_bid_ask_price(string symbol, int price_side) {
    int digits = (int) SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double ask = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_ASK), digits);
    double bid = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_BID), digits);

    if (price_side == 1) return ask;
    if (price_side == 2) return bid;

    return 0.0;
}
