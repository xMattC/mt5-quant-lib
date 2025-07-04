enum MODE_SPLIT_DATA{
    NO_SPLIT,   
    ODD_YEARS,  
    EVEN_YEARS,
    ODD_MONTHS,
    EVEN_MONTHS,
    ODD_WEEKS,
    EVEN_WEEKS     
};

class TestDataSplit {
public:
   bool in_test_period(MODE_SPLIT_DATA data_split_method);
};

bool TestDataSplit::in_test_period(MODE_SPLIT_DATA data_split_method) {
   string result[];
   string string_tc = TimeToString(TimeCurrent());

   // Extract components from datetime string (assumes YYYY.MM.DD format)
   ushort u_sep = StringGetCharacter(".", 0);
   StringSplit(string_tc, u_sep, result);

   bool odd_year = int(result[0]) % 2;
   bool odd_month = int(result[1]) % 2;

   // Calculate week of the year (basic approximation)
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int iDay = (dt.day_of_week + 6) % 7 + 1;                 // Convert to 1=Mon,...,7=Sun
   int iWeek = (dt.day_of_year - iDay + 10) / 7;            // Estimate ISO week number
   bool odd_week = iWeek % 2;

   // Split logic depending on mode
   if (data_split_method == NO_SPLIT)
      return true;
   if (data_split_method == ODD_YEARS && odd_year)
      return true;
   if (data_split_method == EVEN_YEARS && !odd_year)
      return true;
   if (data_split_method == ODD_MONTHS && odd_month)
      return true;
   if (data_split_method == EVEN_MONTHS && !odd_month)
      return true;
   if (data_split_method == ODD_WEEKS && odd_week)
      return true;
   if (data_split_method == EVEN_WEEKS && !odd_week)
      return true;

   return false;
}
