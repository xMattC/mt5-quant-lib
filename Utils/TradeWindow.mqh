#include <MyLibs/Utils/TimeZones.mqh>

class TradeSessionUtils {

protected:
   TimeZones tz;                   // For handling timezone conversion
   bool in_window;                 // Whether the current time is in the allowed window
   datetime start_time;           // Session start time (converted to Broker time)
   datetime end_time;             // Session end time (converted to Broker time)

public:
   bool trade_window(string t1, string t2, string time_zone = "Broker", bool plot_range_inp = true);
};

bool TradeSessionUtils::trade_window(string t1, string t2, string time_zone, bool plot_range_inp) {
   datetime _t1 = StringToTime(t1);   // Convert string to datetime
   datetime _t2 = StringToTime(t2);   // Convert string to datetime

   // Handle overnight windows (e.g. 22:00–01:00)
   if (_t1 > _t2) {
      _t2 = _t2 + PeriodSeconds(PERIOD_D1);
   }

   int w_duration = (int)(_t2 - _t1);   // Duration of the session in seconds

   // Check if we're currently within the window
   if (TimeCurrent() >= start_time && TimeCurrent() <= end_time) {
      in_window = true;
   }

   // If we've moved beyond the previous window, define a new one
   if (TimeCurrent() >= end_time) {
      in_window = false;

      // Convert start time to broker time based on user timezone input
      start_time = tz.timezone_conversions(time_zone, StringToTime(t1), "Broker");

      // If we've already passed today's start time, push it to tomorrow
      if (TimeCurrent() >= start_time) {
         start_time += PeriodSeconds(PERIOD_D1);
      }

      // End time is relative to updated start time
      end_time = start_time + w_duration;

      // Plot vertical lines if requested
      if (plot_range_inp) {
         string name = "Start Time" + (string)start_time;
         if (start_time > 0) {
            ObjectCreate(NULL, name, OBJ_VLINE, 0, start_time, 0);
            ObjectSetInteger(NULL, name, OBJPROP_COLOR, clrBlue);
            ObjectSetInteger(NULL, name, OBJPROP_BACK, true);
         }

         name = "End Time" + (string)end_time;
         if (end_time > 0) {
            ObjectCreate(NULL, name, OBJ_VLINE, 0, end_time, 0);
            ObjectSetInteger(NULL, name, OBJPROP_COLOR, C'56,108,26');
            ObjectSetInteger(NULL, name, OBJPROP_BACK, true);
         }

         ChartRedraw();
      }
   }

   return in_window;
}
