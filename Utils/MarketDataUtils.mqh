class MarketDataUtils {
public:
   bool     is_new_bar(string symbol, ENUM_TIMEFRAMES time_frame, string daily_start_time = "00:10");
   double   get_latest_buffer_value(int handle);
   double   get_buffer_value(int handle, int shift);
   double   adjusted_point(string symbol);
   double   get_bid_ask_price(string symbol, int price_side);

protected:
   datetime previousTimes[];  // Stores last recorded open time per key
   string   bar_keys[];       // Keys are symbol+TF combinations, e.g. "EURUSD_PERIOD_H1"
};

// Helper function to find index of a key in an array
int LinearSearch(string &arr[], string target) {
   for (int i = 0; i < ArraySize(arr); i++) {
      if (arr[i] == target)
         return i;
   }
   return -1;  // Not found
}

// Checks if a new bar has opened on the given timeframe and symbol
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
      // For daily timeframe, wait for specific time (e.g., 00:10) before triggering
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

   return false;  // No new bar
}

// shift = 0 refers to the live candle (still forming)
// shift = 1 is the most recently closed candle
// shift = 2 is the one before that, etc.
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
