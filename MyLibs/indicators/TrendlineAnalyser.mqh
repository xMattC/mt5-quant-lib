#include <MyLibs/Utils/MarketDataUtils.mqh>

// ---------------------------------------------------------------------
// CLASS: TrendlineAnalyser
// ---------------------------------------------------------------------
// A utility class to detect price crossovers with a trendline buffer.
// Supports both crossover detection and trend direction checks.
// ---------------------------------------------------------------------
class TrendlineAnalyser {
private:
    MarketDataUtils market_data_utils;

public:
    void detect_cross(string symbol, int handle, bool& cross_long, bool& cross_short, int shift = 1);
    void trend_direction(string symbol, int handle, bool& direction_long, bool& direction_short, int shift = 1);
};

// ---------------------------------------------------------------------
// Detects whether price has crossed above (long) or below (short)
// a trendline between the two most recent closed bars.
//
// Parameters:
// - symbol       : Trading symbol (e.g., "EURUSD").
// - handle       : Indicator handle for the trendline buffer.
// - cross_long   : Output true if bullish crossover detected.
// - cross_short  : Output true if bearish crossover detected.
// - shift        : Bar shift to evaluate (default: 1 = last closed bar).
//
// Logic:
// - Retrieves price and trendline values for the current and previous bar.
// - Checks for a crossover by comparing price vs trendline movement.
// ---------------------------------------------------------------------
void TrendlineAnalyser::detect_cross(string symbol, int handle, bool& cross_long, bool& cross_short, int shift) {
    cross_long = false;
    cross_short = false;

    double price = iClose(symbol, PERIOD_CURRENT, shift);
    double prev_price = iClose(symbol, PERIOD_CURRENT, shift + 1);

    double trendline = market_data_utils.get_buffer_value(handle, shift);
    double prev_trendline = market_data_utils.get_buffer_value(handle, shift + 1);

    if (price == EMPTY_VALUE || prev_price == EMPTY_VALUE || trendline == EMPTY_VALUE || prev_trendline == EMPTY_VALUE)
        return;

    cross_long  = (prev_price < prev_trendline && price > trendline);
    cross_short = (prev_price > prev_trendline && price < trendline);
}

// ---------------------------------------------------------------------
// Checks if price is currently above or below the trendline.
//
// Parameters:
// - symbol           : Trading symbol (e.g., "EURUSD").
// - handle           : Trendline indicator handle.
// - direction_long   : Output true if price is above trendline.
// - direction_short  : Output true if price is below trendline.
// - shift            : Bar index to check (default: 1).
//
// Logic:
// - Retrieves price and trendline at the specified shift.
// - Compares relative position of price to trendline.
// ---------------------------------------------------------------------
void TrendlineAnalyser::trend_direction(string symbol, int handle, bool& direction_long, bool& direction_short, int shift) {
    direction_long = false;
    direction_short = false;

    double price = iClose(symbol, PERIOD_CURRENT, shift);
    double trendline = market_data_utils.get_buffer_value(handle, shift);

    if (price == EMPTY_VALUE || trendline == EMPTY_VALUE)
        return;

    direction_long  = (price > trendline);
    direction_short = (price < trendline);
}
