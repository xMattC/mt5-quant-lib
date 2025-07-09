#include <MyLibs/Utils/MarketDataUtils.mqh>

class AtrBands {
   private:
    MarketDataUtils market_data_utils;

   public:
    // Core band accessors
    double upper_band(string symbol, double trendline_var, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1, 
                        color clr = clrDodgerBlue, int width = 1, bool plot = true);

    double lower_band(string symbol, double trendline_var, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1, 
                        color clr = clrDodgerBlue, int width = 1, bool plot = true);

    double middle_band(string symbol, double trendline_var, ENUM_TIMEFRAMES tf, int shift = 1, color clr = clrDodgerBlue, int width = 1, 
                        bool plot = true);

    // Band checkers
    bool inside_upper_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1, bool plot = true);

    bool inside_lower_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1, bool plot = true);

    bool crossed_below_upper_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1, 
                                    bool plot = true);

    bool crossed_above_lower_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult = 1.0, int shift = 1, 
                                    bool plot = true);
   protected:
    double get_atr(string symbol, int atr_period, ENUM_TIMEFRAMES tf, int shift);
    void draw_line(string name, double price, color clr, int width);
};

// -------------------
// Public Methods
// -------------------

double AtrBands::upper_band(string symbol, double trendline_var, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift, color clr, int width, bool plot) {
    double atr = get_atr(symbol, atr_period, tf, shift);
    double upper = trendline_var + atr * mult;
    if (plot && shift == 1) draw_line("ATRBand_Upper_" + symbol, upper, clr, width); // persistent line
    return upper;
}

double AtrBands::lower_band(string symbol, double trendline_var, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift, color clr, int width, bool plot) {
    double atr = get_atr(symbol, atr_period, tf, shift);
    double lower = trendline_var - atr * mult;
    if (plot && shift == 1) draw_line("ATRBand_Lower_" + symbol, lower, clr, width); // persistent line
    return lower;
}

double AtrBands::middle_band(string symbol, double trendline_var, ENUM_TIMEFRAMES tf, int shift, color clr, int width, bool plot) {
    if (plot && shift == 1) draw_line("ATRBand_Mid_" + symbol, trendline_var, clr, width); // persistent line
    return trendline_var;
}

bool AtrBands::inside_upper_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift, bool plot) {
    double price = iClose(symbol, tf, shift);
    double trendline_var = market_data_utils.get_buffer_value(handle, shift);
    double upper = upper_band(symbol, trendline_var, atr_period, tf, mult, shift, clrDodgerBlue, 1, plot);

    if (price == EMPTY_VALUE || trendline_var == EMPTY_VALUE || upper == EMPTY_VALUE) return false;
    return (price > trendline_var && price < upper);
}

bool AtrBands::inside_lower_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift, bool plot) {
    double price = iClose(symbol, tf, shift);
    double trendline_var = market_data_utils.get_buffer_value(handle, shift);
    double lower = lower_band(symbol, trendline_var, atr_period, tf, mult, shift, clrDodgerBlue, 1, plot);

    if (price == EMPTY_VALUE || trendline_var == EMPTY_VALUE || lower == EMPTY_VALUE) return false;
    return (price < trendline_var && price > lower);
}

// pull-back inside upper atr band:
bool AtrBands::crossed_below_upper_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift, bool plot) {
    //--- checked bar
    double price = iClose(symbol, tf, shift);
    double trendline_var = market_data_utils.get_buffer_value(handle, shift);
    double atr_upper_band = upper_band(symbol, trendline_var, atr_period, tf, mult, shift, clrDodgerBlue, 1, plot);

    //--- previous bar
    double prev_price = iClose(symbol, tf, shift + 1);
    double prev_trendline_var = market_data_utils.get_buffer_value(handle, shift + 1);
    double prev_atr_upper_band = upper_band(symbol, prev_trendline_var, atr_period, tf, mult, shift + 1, clrDodgerBlue, 1, plot);

    if (price == EMPTY_VALUE || trendline_var == EMPTY_VALUE || atr_upper_band == EMPTY_VALUE || prev_price == EMPTY_VALUE 
        || prev_trendline_var == EMPTY_VALUE || prev_atr_upper_band == EMPTY_VALUE) return false;

    return (prev_price > prev_atr_upper_band && price < atr_upper_band);
}

// pull-back inside lower atr band:
bool AtrBands::crossed_above_lower_band(string symbol, int handle, int atr_period, ENUM_TIMEFRAMES tf, double mult, int shift, bool plot) {
    //--- checked bar
    double price = iClose(symbol, tf, shift);
    double trendline_var = market_data_utils.get_buffer_value(handle, shift);
    double atr_lower_band = lower_band(symbol, trendline_var, atr_period, tf, mult, shift, clrDodgerBlue, 1, plot);

    //--- previous bar
    double prev_price = iClose(symbol, tf, shift + 1);
    double prev_trendline_var = market_data_utils.get_buffer_value(handle, shift + 1);
    double prev_atr_lower_band = lower_band(symbol, prev_trendline_var, atr_period, tf, mult, shift + 1, clrDodgerBlue, 1, plot);

    if (price == EMPTY_VALUE || trendline_var == EMPTY_VALUE || atr_lower_band == EMPTY_VALUE || prev_price == EMPTY_VALUE 
        || prev_trendline_var == EMPTY_VALUE || prev_atr_lower_band == EMPTY_VALUE) return false;

    return (prev_price < prev_atr_lower_band && price > atr_lower_band);
}

// -------------------
// Internal Helpers
// -------------------

double AtrBands::get_atr(string symbol, int atr_period, ENUM_TIMEFRAMES tf, int shift) {
    int handle = iATR(symbol, tf, atr_period);
    if (handle == INVALID_HANDLE) {
        Print("Failed to create ATR handle for ", symbol);
        return 0.0;
    }

    double buf[];
    ArraySetAsSeries(buf, true);
    if (CopyBuffer(handle, 0, shift, 1, buf) == 1 && buf[0] != EMPTY_VALUE) return buf[0];

    return 0.0;
}

void AtrBands::draw_line(string name, double price, color clr, int width) {
    if (ObjectFind(0, name) < 0) {
        ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
    } else {
        ObjectSetDouble(0, name, OBJPROP_PRICE, price);
    }

    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
    ObjectSetInteger(0, name, OBJPROP_BACK, true);
}
