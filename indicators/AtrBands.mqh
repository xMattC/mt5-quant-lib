// File: MyLibs/Utils/AtrBands.mqh

class AtrBands {
   protected:
    string symbol;
    int atr_period;
    ENUM_TIMEFRAMES timeframe;
    string prefix;
    color upper_color;
    color lower_color;
    color mid_color;
    int line_width;
    bool plot_bands;
    int atr_handle;

   public:
    AtrBands(string _symbol, int _atr_period = 14, ENUM_TIMEFRAMES _timeframe = PERIOD_CURRENT,
             color _upper = clrDodgerBlue, color _lower = clrDodgerBlue, color _mid = clrDodgerBlue,
             int _width = 1, bool plot = true);

    double upper_band(double baseline, int shift = 1, double mult = 1.0);
    double lower_band(double baseline, int shift = 1, double mult = 1.0);
    double middle_band(double baseline, int shift = 1);

   protected:
    double get_atr(int shift);
    void draw_line(string name, int shift, double price, color clr);
};

// Constructor
AtrBands::AtrBands(string _symbol, int _atr_period, ENUM_TIMEFRAMES _timeframe,
                   color _upper, color _lower, color _mid, int _width, bool plot) {
    symbol = _symbol;
    atr_period = _atr_period;
    timeframe = _timeframe;
    prefix = "ATRBand";
    upper_color = _upper;
    lower_color = _lower;
    mid_color = _mid;
    line_width = _width;
    plot_bands = plot;

    atr_handle = iATR(symbol, timeframe, atr_period);
    if (atr_handle == INVALID_HANDLE) {
        Print("Failed to create ATR handle for symbol: ", symbol);
    }
}

// Public methods
double AtrBands::upper_band(double baseline, int shift, double mult) {
    double atr = get_atr(shift);
    double upper = baseline + atr * mult;
    if (plot_bands) draw_line(prefix + "_Upper_" + symbol, shift, upper, upper_color);
    return upper;
}

double AtrBands::lower_band(double baseline, int shift, double mult) {
    double atr = get_atr(shift);
    double lower = baseline - atr * mult;
    if (plot_bands) draw_line(prefix + "_Lower_" + symbol, shift, lower, lower_color);
    return lower;
}

double AtrBands::middle_band(double baseline, int shift) {
    if (plot_bands) draw_line(prefix + "_Mid_" + symbol, shift, baseline, mid_color);
    return baseline;
}

// Internal: Get ATR value from buffer
double AtrBands::get_atr(int shift) {
    if (atr_handle == INVALID_HANDLE) return 0;

    double buf[];
    ArraySetAsSeries(buf, true);
    if (CopyBuffer(atr_handle, 0, shift, 1, buf) == 1 && buf[0] != EMPTY_VALUE)
        return buf[0];

    return 0;
}

// Internal: Draw line for a given price at a bar
void AtrBands::draw_line(string name, int shift, double price, color clr) {
    datetime time0 = iTime(symbol, timeframe, shift);
    datetime time1 = time0 + PeriodSeconds(timeframe);

    if (ObjectFind(0, name) < 0) {
        ObjectCreate(0, name, OBJ_TREND, 0, time0, price, time1, price);
    } else {
        ObjectMove(0, name, 0, time0, price);
        ObjectMove(0, name, 1, time1, price);
    }

    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, line_width);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
}
