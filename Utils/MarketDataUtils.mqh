class MarketDataUtils {
public:
   bool     is_new_bar(string symbol, ENUM_TIMEFRAMES time_frame, string daily_start_time = "00:10");
   double   get_latest_buffer_value(int handle);
   double   get_buffer_value(int handle, int shift);
   double   adjusted_point(string symbol);
   double   get_bid_ask_price(string symbol, int price_side);

protected:
   datetime previousTime;    // Stores the last recorded bar open time
   datetime bar_open_time;   // Stores the current bar's open time
};

// Checks if a new bar has opened on the given timeframe and symbol
bool MarketDataUtils::is_new_bar(string symbol, ENUM_TIMEFRAMES time_frame, string daily_start_time) {
   bar_open_time = iTime(symbol, time_frame, 0);  // Current open time

   if (previousTime != bar_open_time) {
      // For daily timeframe, wait for specific time (e.g., 00:10) before triggering
      if (PeriodSeconds(time_frame) == PeriodSeconds(PERIOD_D1)) {
         if (TimeCurrent() > StringToTime(daily_start_time)) {
            previousTime = bar_open_time;
            return true;
         }
      } else {
         previousTime = bar_open_time;
         return true;
      }
   }

   return false;  // No new bar
}

// Retrieves the latest value from an indicator buffer (shift 0)
double MarketDataUtils::get_latest_buffer_value(int handle) {
   double val[];
   ArraySetAsSeries(val, true);  // Aligns array with bar indexing (0 = latest)

   if (CopyBuffer(handle, 0, 0, 1, val) == 1)
      return val[0];  // Latest value at shift 0

   return 0.0;
}

// shift = 0 refers to the live candle (still forming)
// shift = 1 is the most recently closed candle
// shift = 2 is the one before that, etc.
double MarketDataUtils::get_buffer_value(int handle, int shift) {

    double val[];
    ArraySetAsSeries(val, true);

    if (CopyBuffer(handle, 0, shift, 1, val) == 1 && val[0] != EMPTY_VALUE)
        return val[0];

    return EMPTY_VALUE;
}


// Adjusts the point value for symbol to account for fractional pips (e.g., 5-digit brokers)
double MarketDataUtils::adjusted_point(string symbol) {
   int symbol_digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   int digits_adjust = (symbol_digits == 3 || symbol_digits == 5) ? 10 : 1;
   double point_val = SymbolInfoDouble(symbol, SYMBOL_POINT);
   return point_val * digits_adjust;  // Adjusted pip value
}

// Returns current Bid or Ask price for a symbol based on side (1 = Ask, 2 = Bid)
double MarketDataUtils::get_bid_ask_price(string symbol, int price_side) {
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double ask = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_ASK), digits);
   double bid = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_BID), digits);

   if (price_side == 1) return ask;
   if (price_side == 2) return bid;

   return 0.0;  // Invalid input
}
