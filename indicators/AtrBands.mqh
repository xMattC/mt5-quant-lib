#include <MyLibs/Utils/MarketDataUtils.mqh>
#include <MyLibs/Utils/AtrHandleManager.mqh>

class AtrBands {
private:
    MarketDataUtils market_data_utils;
    AtrHandleManager atr_manager;

public:
    // Core band accessors
    double upper_band(string symbol, double trendline_var, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1);
    double lower_band(string symbol, double trendline_var, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1);
    double middle_band(string symbol, double trendline_var, ENUM_TIMEFRAMES tf, int shift = 1);

    // Band checkers
    bool inside_upper_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1);
    bool inside_lower_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1);
    bool crossed_below_upper_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1);
    bool crossed_above_lower_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1);

    // Plotting
    void plot_bands(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int bars = 100, color clr = clrSkyBlue, int width = 1);


protected:
    double get_atr(string symbol, int atr_period, ENUM_TIMEFRAMES tf, int shift);
};


// -------------------
// Public Methods
// -------------------

double AtrBands::upper_band(string symbol, double trendline_var, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift) {
    double atr = get_atr(symbol, atr_period, tf, shift);
    return trendline_var + atr * mult;
}

double AtrBands::lower_band(string symbol, double trendline_var, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift) {
    double atr = get_atr(symbol, atr_period, tf, shift);
    return trendline_var - atr * mult;
}

double AtrBands::middle_band(string symbol, double trendline_var, ENUM_TIMEFRAMES tf, int shift) {
    return trendline_var;
}

bool AtrBands::inside_upper_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift) {
    double price = iClose(symbol, tf, shift);
    double trendline_var = market_data_utils.get_buffer_value(handle, shift);
    double upper = upper_band(symbol, trendline_var, atr_period, tf, mult, shift);
    if (price == EMPTY_VALUE || trendline_var == EMPTY_VALUE || upper == EMPTY_VALUE) return false;
    return (price > trendline_var && price < upper);
}

bool AtrBands::inside_lower_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift) {
    double price = iClose(symbol, tf, shift);
    double trendline_var = market_data_utils.get_buffer_value(handle, shift);
    double lower = lower_band(symbol, trendline_var, atr_period, tf, mult, shift);
    if (price == EMPTY_VALUE || trendline_var == EMPTY_VALUE || lower == EMPTY_VALUE) return false;
    return (price < trendline_var && price > lower);
}

bool AtrBands::crossed_below_upper_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift) {
    double price = iClose(symbol, tf, shift);
    double prev_price = iClose(symbol, tf, shift + 1);

    double trendline_var = market_data_utils.get_buffer_value(handle, shift);
    double prev_trendline_var = market_data_utils.get_buffer_value(handle, shift + 1);

    double upper = upper_band(symbol, trendline_var, atr_period, tf, mult, shift);
    double prev_upper = upper_band(symbol, prev_trendline_var, atr_period, tf, mult, shift + 1);

    if (price == EMPTY_VALUE || prev_price == EMPTY_VALUE || trendline_var == EMPTY_VALUE || prev_trendline_var == EMPTY_VALUE) return false;

    return (prev_price > prev_upper && price < upper);
}

bool AtrBands::crossed_above_lower_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift) {
    double price = iClose(symbol, tf, shift);
    double prev_price = iClose(symbol, tf, shift + 1);

    double trendline_var = market_data_utils.get_buffer_value(handle, shift);
    double prev_trendline_var = market_data_utils.get_buffer_value(handle, shift + 1);

    double lower = lower_band(symbol, trendline_var, atr_period, tf, mult, shift);
    double prev_lower = lower_band(symbol, prev_trendline_var, atr_period, tf, mult, shift + 1);

    if (price == EMPTY_VALUE || prev_price == EMPTY_VALUE || trendline_var == EMPTY_VALUE || prev_trendline_var == EMPTY_VALUE) return false;

    return (prev_price < prev_lower && price > lower);
}

void AtrBands::plot_bands(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult, int bars, color line_color, int width) {
    for (int i = bars; i >= 1; i--) {
        double trendline = market_data_utils.get_buffer_value(handle, i);
        if (trendline == EMPTY_VALUE) continue;

        double atr = get_atr(symbol, atr_period, tf, i);
        if (atr == EMPTY_VALUE) continue;

        double upper = trendline + atr * mult;
        double lower = trendline - atr * mult;

        datetime time1 = iTime(symbol, tf, i);
        datetime time2 = iTime(symbol, tf, i - 1);

        string upper_name = "ATR_Upper_" + symbol + "_" + TimeToString(time1, TIME_DATE | TIME_MINUTES);
        string lower_name = "ATR_Lower_" + symbol + "_" + TimeToString(time1, TIME_DATE | TIME_MINUTES);
        string middle_name = "ATR_middle_" + symbol + "_" + TimeToString(time1, TIME_DATE | TIME_MINUTES);

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

double AtrBands::get_atr(string symbol, int atr_period, ENUM_TIMEFRAMES tf, int shift) {
    return atr_manager.get_atr_value(symbol, tf, atr_period, shift);
}
