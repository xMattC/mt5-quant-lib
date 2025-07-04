class BarUtils {

protected:
   datetime previousTime;       // Stores the previous bar open time to detect new bars
   datetime bar_open_time;      // Current bar open time

public:
   bool is_new_bar(string symbol, ENUM_TIMEFRAMES time_frame, string daily_start_time = "00:10");
};

bool BarUtils::is_new_bar(string symbol, ENUM_TIMEFRAMES time_frame, string daily_start_time) {
   // Get the open time of the current bar
   bar_open_time = iTime(symbol, time_frame, 0);

   // Check if it's different from the last seen time — this implies a new bar has formed
   if (previousTime != bar_open_time) {

      // Special logic for daily bars: wait until a specific time-of-day threshold
      if (PeriodSeconds(time_frame) == PeriodSeconds(PERIOD_D1)) {
         // Don't trigger on midnight, wait until configured daily_start_time (e.g., "00:10")
         if (TimeCurrent() > StringToTime(daily_start_time)) {
            previousTime = bar_open_time;  // Update the marker
            return true;
         }
      } else {
         // For all non-daily timeframes, treat any change in bar time as new bar
         previousTime = bar_open_time;
         return true;
      }
   }

   // No new bar detected
   return false;
}

