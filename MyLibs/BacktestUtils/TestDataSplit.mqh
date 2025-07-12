// ---------------------------------------------------------------------
// ENUM: MODE_SPLIT_DATA
// ---------------------------------------------------------------------
// Defines how to split data during testing based on time attributes.
//
// Values:
// - NO_SPLIT    : Do not split, always return true.
// - ODD_YEARS   : Include only odd-numbered years.
// - EVEN_YEARS  : Include only even-numbered years.
// - ODD_MONTHS  : Include only odd-numbered months.
// - EVEN_MONTHS : Include only even-numbered months.
// - ODD_WEEKS   : Include only odd-numbered weeks.
// - EVEN_WEEKS  : Include only even-numbered weeks.
// ---------------------------------------------------------------------
enum MODE_SPLIT_DATA {
    NO_SPLIT,   
    ODD_YEARS,  
    EVEN_YEARS,
    ODD_MONTHS,
    EVEN_MONTHS,
    ODD_WEEKS,
    EVEN_WEEKS     
};

// ---------------------------------------------------------------------
// CLASS: TestDataSplit
// ---------------------------------------------------------------------
// Provides logic to determine whether the current date falls within
// a selected split group for testing or optimization purposes.
// ---------------------------------------------------------------------
class TestDataSplit {
public:
    bool in_test_period(MODE_SPLIT_DATA data_split_method);
};

// ---------------------------------------------------------------------
// Determines whether the current time falls in the selected group.
//
// Parameters:
// - data_split_method : Enum value defining the split strategy.
//
// Logic:
// - Extracts current date components (year, month, ISO week).
// - Returns true if current time matches the given split rule.
// ---------------------------------------------------------------------
bool TestDataSplit::in_test_period(MODE_SPLIT_DATA data_split_method) {
    string result[];
    string string_tc = TimeToString(TimeCurrent());

    // Extract components from datetime string (assumes YYYY.MM.DD format)
    ushort u_sep = StringGetCharacter(".", 0);
    StringSplit(string_tc, u_sep, result);

    bool odd_year = int(result[0]) % 2;
    bool odd_month = int(result[1]) % 2;

    // Calculate week of the year (approximate ISO week)
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int i_day = (dt.day_of_week + 6) % 7 + 1;               // Convert to 1=Mon,...,7=Sun
    int i_week = (dt.day_of_year - i_day + 10) / 7;         // Approximate ISO week number
    bool odd_week = i_week % 2;

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
