//+------------------------------------------------------------------+
//|                                                   TimeZones.mqh  |
//|                Handles timezone conversion and time window logic |
//|                                                                  |
//|                                  2025 xMattC (github.com/xMattC) |
//+------------------------------------------------------------------+
#property copyright "2025 xMattC (github.com/xMattC)"
#property link      "https://github.com/xMattC"
#property version   "1.00"


#property library
#include <MyLibs/Utils/DealingWithTime.mqh>
#include <Trade/Trade.mqh>

class TimeZones : public CObject {
   protected:
    string dt_s;
    int len;
    string dt_string;
    datetime tC, tGMT, tNY, tLon, tFfm, tMosc, tSyd, tTok;
    datetime tz_time;
    string tz_date;
    datetime time_start;
    datetime time_end;
    bool is_time;
    datetime tGIVEN;
    datetime tREQ;
    datetime tzt;
    datetime tz_req;
    double required_close;

    double ny_daily_close_protected(string symbol, int shift_days, bool print_data = false);

   public:
    string get_date_string_from_datetime(datetime dt);
    datetime get_timezone_time(string time_zone, bool print_time);
    datetime timezone_conversions(string time_zone_known, datetime time_given, string time_zone_required);
    double ny_daily_close(string symbol, int shift_days, bool print_data = false);
};

// ---------------------------------------------------------------------
// Converts a datetime to a string excluding seconds.
//
// Parameters:
// - dt : Datetime object.
//
// Returns:
// - A string in the format "yyyy.mm.dd hh:mi".
// ---------------------------------------------------------------------
string TimeZones::get_date_string_from_datetime(datetime dt) {
    dt_s = TimeToString(dt);
    len = StringLen(dt_s);
    dt_string = StringSubstr(dt_s, 0, len - 5);
    return dt_string;
}

// ---------------------------------------------------------------------
// Gets the current time in the specified time zone.
//
// Parameters:
// - time_zone  : One of "NY", "Lon", "Ffm", "Syd", "Mosc", "Tok".
// - print_time : If true, logs various times for debugging.
//
// Returns:
// - Current time in the specified time zone.
// ---------------------------------------------------------------------
datetime TimeZones::get_timezone_time(string time_zone, bool print_time) {
    checkTimeOffset(TimeCurrent());  // Adjust DST

    tC = TimeCurrent();
    tGMT = TimeCurrent() + OffsetBroker.actOffset;
    tNY = tGMT - (NYShift + DST_USD);
    tLon = tGMT - (LondonShift + DST_EUR);
    tFfm = tGMT - (FfmShift + DST_EUR);
    tSyd = tGMT - (SidneyShift + DST_AUD);
    tMosc = tGMT - (MoskwaShift + DST_RUS);
    tTok = tGMT - (TokyoShift);

    if (print_time) {
        Print("----------------------------------");
        Print("Broker: ", tC);
        Print("GMT: ", tGMT);
        Print("time in New York: ", tNY);
        Print("time in London: ", tLon);
        Print("time in Frankfurt: ", tFfm);
        Print("time in Sidney: ", tSyd);
        Print("time in Moscow: ", tMosc);
        Print("time in Tokyo: ", tTok);
    }

    if (time_zone == "NY") return tNY;
    if (time_zone == "Lon") return tLon;
    if (time_zone == "Ffm") return tFfm;
    if (time_zone == "Syd") return tSyd;
    if (time_zone == "Mosc") return tMosc;
    if (time_zone == "Tok") return tTok;

    return NULL;
}

// ---------------------------------------------------------------------
// Converts a datetime from one timezone to another.
//
// Parameters:
// - time_zone_known    : Original timezone of the datetime.
// - time_given         : The datetime to convert.
// - time_zone_required : Desired output timezone.
//
// Returns:
// - The equivalent datetime in the target timezone.
// ---------------------------------------------------------------------
datetime TimeZones::timezone_conversions(string time_zone_known, datetime time_given, string time_zone_required) {
    tGIVEN = time_given;
    checkTimeOffset(tGIVEN);  // Adjust DST

    // Step 1: Convert known timezone to GMT
    if (time_zone_known == "GMT") tGMT = tGIVEN;
    if (time_zone_known == "Broker") tGMT = tGIVEN + OffsetBroker.actOffset;
    if (time_zone_known == "NY") tGMT = tGIVEN + (NYShift + DST_USD);
    if (time_zone_known == "Lon") tGMT = tGIVEN + (LondonShift + DST_EUR);
    if (time_zone_known == "Ffm") tGMT = tGIVEN + (FfmShift + DST_EUR);
    if (time_zone_known == "Syd") tGMT = tGIVEN + (SidneyShift + DST_AUD);
    if (time_zone_known == "Mosc") tGMT = tGIVEN + (MoskwaShift + DST_RUS);
    if (time_zone_known == "Tok") tGMT = tGIVEN + (TokyoShift);

    // Step 2: Convert GMT to required timezone
    if (time_zone_required == "GMT") tREQ = tGMT;
    if (time_zone_required == "Broker") tREQ = tGMT - OffsetBroker.actOffset;
    if (time_zone_required == "NY") tREQ = tGMT - (NYShift + DST_USD);
    if (time_zone_required == "Lon") tREQ = tGMT - (LondonShift + DST_EUR);
    if (time_zone_required == "Ffm") tREQ = tGMT - (FfmShift + DST_EUR);
    if (time_zone_required == "Syd") tREQ = tGMT - (SidneyShift + DST_AUD);
    if (time_zone_required == "Mosc") tREQ = tGMT - (MoskwaShift + DST_RUS);
    if (time_zone_required == "Tok") tREQ = tGMT - (TokyoShift);

    return tREQ;
}

// ---------------------------------------------------------------------
// Returns the most recent NY daily close price.
//
// Parameters:
// - symbol      : Trading symbol.
// - shift_days  : How many NY daily closes back to return.
// - print_data  : If true, logs debug information.
//
// Returns:
// - The NY close price.
// ---------------------------------------------------------------------
double TimeZones::ny_daily_close(string symbol, int shift_days, bool print_data) {
    required_close = ny_daily_close_protected(symbol, shift_days, print_data);
    return required_close;
}

// ---------------------------------------------------------------------
// Internal implementation to compute NY daily close price.
//
// Logic:
// - Defines NY close as 5pm NY time = 00:00 broker + 17H back.
// - Adjusts for day shifts if required.
// - Returns the close price of the NY daily session.
// ---------------------------------------------------------------------
double TimeZones::ny_daily_close_protected(string symbol, int shift_days, bool print_data) {
    datetime time_5pm = iTime(symbol, PERIOD_D1, 0) - (PeriodSeconds(PERIOD_H1) * 7);
    datetime ny_close_in_brokers_time = timezone_conversions("NY", time_5pm, "Broker");
    datetime ny_close_time = ny_close_in_brokers_time + PeriodSeconds(PERIOD_D1);

    if (TimeCurrent() < ny_close_time) ny_close_time -= PeriodSeconds(PERIOD_D1);

    int shift = iBarShift(symbol, PERIOD_H1, ny_close_time, false) + 1;
    shift += (24 * (shift_days - 1));

    double ny_close = iClose(symbol, PERIOD_H1, shift);
    double br_close = iClose(symbol, PERIOD_H1, 1);

    if (print_data) {
        Print("shift ", shift);
        Print("time_5pm ", time_5pm);
        Print("ny_close_in_brokers_time ", ny_close_in_brokers_time);
        Print("ny_close_time ", ny_close_time);
        Print("ny_close ", ny_close);
        Print("br_close ", br_close);
    }

    return ny_close;
}