#include <MyLibs/Utils/MarketDataUtils.mqh>
//+------------------------------------------------------------------+
//| TrendlineSignal: A utility class to detect trendline crossovers |
//+------------------------------------------------------------------+
class TrendlineAnalyser {
   private:
    MarketDataUtils market_data_utils;

   public:
    // Main method: detects whether price has crossed the trendline up (long) or down (short)
    // Parameters:
    // - symbol: the symbol we're evaluating (e.g., "EURUSD")
    // - handle: the indicator handle for the trendline (e.g., iMA handle)
    // - cross_long: output bool set to true if a bullish cross is detected
    // - cross_short: output bool set to true if a bearish cross is detected
    void detect_cross(string symbol, int handle, bool& cross_long, bool& cross_short, int shift=1) {
        cross_long = false;
        cross_short = false;

        // --- Retrieve prices and trendline values from last 2 closed bars
        double price = iClose(symbol, PERIOD_CURRENT, shift);       // most recent closed bar
        double prev_price = iClose(symbol, PERIOD_CURRENT, shift + 1);  // bar before that

        double trendline = market_data_utils.get_buffer_value(handle, shift);       // trendline now
        double prev_trendline = market_data_utils.get_buffer_value(handle, shift+1);  // trendline before

        // --- Exit early if any of the data is missing or invalid
        if (price == EMPTY_VALUE || prev_price == EMPTY_VALUE || trendline == EMPTY_VALUE || prev_trendline == EMPTY_VALUE) {
            return;
        }

        // --- Detect bullish crossover (price moves from below to above the trendline)
        cross_long = (prev_price < prev_trendline && price > trendline);

        // --- Detect bearish crossover (price moves from above to below the trendline)
        cross_short = (prev_price > prev_trendline && price < trendline);
    }
    // METHOD: determines if price is currently trending above or below the trendline
    // Parameters:
    // - symbol: trading symbol (e.g., "EURUSD")
    // - handle: trendline indicator handle
    // - is_direction_long: output bool, true if price is above trendline
    // - is_direction_short: output bool, true if price is below trendline
    // - shift: which candle to check (default: 1 = last closed bar)
    void trend_direction(string symbol, int handle, bool& direction_long, bool& direction_short, int shift = 1) {
        direction_long = false;
        direction_short = false;

        double price = iClose(symbol, PERIOD_CURRENT, shift);
        double trendline = market_data_utils.get_buffer_value(handle, shift);

        if (price == EMPTY_VALUE || trendline == EMPTY_VALUE) {
            return;
        }

        direction_long = (price > trendline);
        direction_short = (price < trendline);
    }
};
