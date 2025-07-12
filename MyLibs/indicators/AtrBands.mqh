#include <MyLibs/Utils/MarketDataUtils.mqh>
#include <MyLibs/Utils/AtrHandleManager.mqh>

// ---------------------------------------------------------------------
// CLASS: AtrBands
// ---------------------------------------------------------------------
// Provides ATR-based upper/lower/middle band calculations and checks.
// Useful for volatility-based stop placement, trend filters, or overlays.
// ---------------------------------------------------------------------
class AtrBands {
private:
    MarketDataUtils market_data_utils;
    AtrHandleManager atr_manager;

    double get_atr(string symbol, int atr_period, ENUM_TIMEFRAMES tf, int shift);

public:
    double upper_band(string symbol, double trendline_var, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1);
    double lower_band(string symbol, double trendline_var, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1);
    double middle_band(string symbol, double trendline_var, ENUM_TIMEFRAMES tf, int shift = 1);
    bool inside_upper_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1);
    bool inside_lower_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1);
    bool crossed_below_upper_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1);
    bool crossed_above_lower_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1);
    void plot_bands(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int bars = 100, color clr = clrSkyBlue, int width = 1);
};

// ---------------------------------------------------------------------
// Returns the upper ATR band level.
//
// Parameters:
// - symbol        : Symbol to use.
// - trendline_var : Base trendline value (e.g., MA).
// - atr_period    : ATR period.
// - tf            : Timeframe for ATR.
// - mult          : ATR multiplier.
// - shift         : Bar shift to evaluate.
// ---------------------------------------------------------------------
double AtrBands::upper_band(string symbol, double trendline_var, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift) {
    double atr = get_atr(symbol, atr_period, tf, shift);
    return trendline_var + atr * mult;
}

// ---------------------------------------------------------------------
// Returns the lower ATR band level.
//
// Parameters:
// - Same as upper_band, except lower band logic.
// ---------------------------------------------------------------------
double AtrBands::lower_band(string symbol, double trendline_var, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift) {
    double atr = get_atr(symbol, atr_period, tf, shift);
    return trendline_var - atr * mult;
}

// ---------------------------------------------------------------------
// Returns the middle band, which is simply the trendline.
//
// Parameters:
// - symbol        : Symbol.
// - trendline_var : The trendline value.
// - tf            : Timeframe (unused here).
// - shift         : Shift index (unused here).
// ---------------------------------------------------------------------
double AtrBands::middle_band(string symbol, double trendline_var, ENUM_TIMEFRAMES tf, int shift) {
    return trendline_var;
}

// ---------------------------------------------------------------------
// Checks if price is between trendline and upper band.
//
// Logic:
// - Retrieves trendline and price.
// - Compares if price lies between trendline and upper band.
// ---------------------------------------------------------------------
bool AtrBands::inside_upper_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift) {
    double price = iClose(symbol, tf, shift);
    double trendline_var = market_data_utils.get_buffer_value(handle, shift);
    double upper = upper_band(symbol, trendline_var, atr_period, tf, mult, shift);
    if (price == EMPTY_VALUE || trendline_var == EMPTY_VALUE || upper == EMPTY_VALUE)
        return false;
    return (price > trendline_var && price < upper);
}

// ---------------------------------------------------------------------
// Checks if price is between trendline and lower band.
//
// Logic:
// - Retrieves trendline and price.
// - Compares if price lies between trendline and lower band.
// ---------------------------------------------------------------------
bool AtrBands::inside_lower_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift) {
    double price = iClose(symbol, tf, shift);
    double trendline_var = market_data_utils.get_buffer_value(handle, shift);
    double lower = lower_band(symbol, trendline_var, atr_period, tf, mult, shift);
    if (price == EMPTY_VALUE || trendline_var == EMPTY_VALUE || lower == EMPTY_VALUE)
        return false;
    return (price < trendline_var && price > lower);
}

// ---------------------------------------------------------------------
// Detects if price has crossed below the upper band.
//
// Logic:
// - Checks crossover from above to below upper band between bars [shift+1] and [shift].
// ---------------------------------------------------------------------
bool AtrBands::crossed_below_upper_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift) {
    double price = iClose(symbol, tf, shift);
    double prev_price = iClose(symbol, tf, shift + 1);
    double trendline_var = market_data_utils.get_buffer_value(handle, shift);
    double prev_trendline_var = market_data_utils.get_buffer_value(handle, shift + 1);
    double upper = upper_band(symbol, trendline_var, atr_period, tf, mult, shift);
    double prev_upper = upper_band(symbol, prev_trendline_var, atr_period, tf, mult, shift + 1);

    if (price == EMPTY_VALUE || prev_price == EMPTY_VALUE || trendline_var == EMPTY_VALUE || prev_trendline_var == EMPTY_VALUE)
        return false;

    return (prev_price > prev_upper && price < upper);
}

// ---------------------------------------------------------------------
// Detects if price has crossed above the lower band.
//
// Logic:
// - Checks crossover from below to above lower band between bars [shift+1] and [shift].
// ---------------------------------------------------------------------
bool AtrBands::crossed_above_lower_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift) {
    double price = iClose(symbol, tf, shift);
    double prev_price = iClose(symbol, tf, shift + 1);
    double trendline_var = market_data_utils.get_buffer_value(handle, shift);
    double prev_trendline_var = market_data_utils.get_buffer_value(handle, shift + 1);
    double lower = lower_band(symbol, trendline_var, atr_period, tf, mult, shift);
    double prev_lower = lower_band(symbol, prev_trendline_var, atr_period, tf, mult, shift + 1);

    if (price == EMPTY_VALUE || prev_price == EMPTY_VALUE || trendline_var == EMPTY_VALUE || prev_trendline_var == EMPTY_VALUE)
        return false;

    return (prev_price < prev_lower && price > lower);
}

// ---------------------------------------------------------------------
// Plots the ATR bands as OBJ_TREND lines on chart.
//
// Parameters:
// - symbol     : Symbol to draw on.
// - handle     : Trendline handle (e.g., MA).
// - atr_period : ATR period for bands.
// - tf         : Timeframe.
// - mult       : ATR multiplier.
// - bars       : Number of bars to plot.
// - clr        : Line color.
// - width      : Line width.
// ---------------------------------------------------------------------
void AtrBands::plot_bands(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult, int bars, color line_color, int width) {
    for (int i = bars; i >= 1; i--) {
        double trendline = market_data_utils.get_buffer_value(handle, i);
        if (trendline == EMPTY_VALUE)
            continue;

        double atr = get_atr(symbol, atr_period, tf, i);
        if (atr == EMPTY_VALUE)
            continue;

        double upper = trendline + atr * mult;
        double lower = trendline - atr * mult;
        datetime time1 = iTime(symbol, tf, i);
        datetime time2 = iTime(symbol, tf, i - 1);

        string upper_name  = "ATR_Upper_"  + symbol + "_" + TimeToString(time1, TIME_DATE | TIME_MINUTES);
        string lower_name  = "ATR_Lower_"  + symbol + "_" + TimeToString(time1, TIME_DATE | TIME_MINUTES);
        string middle_name = "ATR_Middle_" + symbol + "_" + TimeToString(time1, TIME_DATE | TIME_MINUTES);

        if (ObjectFind(0, upper_name) < 0) {
            ObjectCreate(0, upper_name, OBJ_TREND, 0, time1, upper, time2, upper);
            ObjectSetInteger(0, upper_name, OBJPROP_COLOR, line_color);
            ObjectSetInteger(0, upper_name, OBJPROP_WIDTH, width);
            ObjectSetInteger(0, upper_name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, upper_name, OBJPROP_BACK, true);
            ObjectSetInteger(0, upper_name, OBJPROP_SELECTED, false);
        }

        if (ObjectFind(0, lower_name) < 0) {
            ObjectCreate(0, lower_name, OBJ_TREND, 0, time1, lower, time2, lower);
            ObjectSetInteger(0, lower_name, OBJPROP_COLOR, line_color);
            ObjectSetInteger(0, lower_name, OBJPROP_WIDTH, width);
            ObjectSetInteger(0, lower_name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, lower_name, OBJPROP_BACK, true);
            ObjectSetInteger(0, lower_name, OBJPROP_SELECTED, false);
        }

        if (ObjectFind(0, middle_name) < 0) {
            ObjectCreate(0, middle_name, OBJ_TREND, 0, time1, trendline, time2, trendline);
            ObjectSetInteger(0, middle_name, OBJPROP_COLOR, line_color);
            ObjectSetInteger(0, middle_name, OBJPROP_WIDTH, width);
            ObjectSetInteger(0, middle_name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, middle_name, OBJPROP_BACK, true);
            ObjectSetInteger(0, middle_name, OBJPROP_SELECTED, false);
        }
    }

    ChartRedraw();
}

// ---------------------------------------------------------------------
// Retrieves the ATR value via the shared ATR manager.
//
// Parameters:
// - symbol     : Symbol to calculate ATR on.
// - atr_period : ATR calculation period.
// - tf         : Timeframe of the ATR.
// - shift      : Bar index to retrieve.
//
// Returns:
// - The ATR value at the given shift.
// ---------------------------------------------------------------------
double AtrBands::get_atr(string symbol, int atr_period, ENUM_TIMEFRAMES tf, int shift) {
    return atr_manager.get_atr_value(symbol, tf, atr_period, shift);
}
