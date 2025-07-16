//+------------------------------------------------------------------+
//|                                                  CustomeMax.mqh  |
//|            Defines custom optimization criteria for backtesting  |
//|                                                                  |
//|                                  2025 xMattC (github.com/xMattC) |
//+------------------------------------------------------------------+
#property copyright "2025 xMattC (github.com/xMattC)"
#property link      "https://github.com/xMattC"
#property version   "1.00"

#include <Trade/Trade.mqh>

enum CUSTOM_MAX_TYPE {
    CM_WIN_LOSS_RATIO,
    CM_WIN_PERCENT
};

class CustomMax : public CObject {
protected:
    double custom_criteria;

    double win_loss_ratio(int min_required_trades);
    double win_percent_min_trades(int min_required_trades);

public:
    double calculate_custom_criteria(CUSTOM_MAX_TYPE cm_type, int min_trades = 0);
};

// ---------------------------------------------------------------------
// Calculates the selected custom criteria metric.
//
// Parameters:
// - cm_type     : The selected criteria type to calculate.
// - min_trades  : Optional minimum number of trades (default 0).
//
// Logic:
// - Calls the appropriate private method based on cm_type.
// - Returns the resulting metric (or 0 if invalid).
// ---------------------------------------------------------------------
double CustomMax::calculate_custom_criteria(CUSTOM_MAX_TYPE cm_type, int min_trades) {
    switch(cm_type) {
        case CM_WIN_LOSS_RATIO:
            custom_criteria = win_loss_ratio(min_trades);
            break;
        case CM_WIN_PERCENT:
            custom_criteria = win_percent_min_trades(min_trades);
            break;
        default:
            custom_criteria = 0;
            break;
    }
    return custom_criteria;
}

// ---------------------------------------------------------------------
// Calculates win/loss ratio with a minimum trade count check.
//
// Parameters:
// - min_required_trades : Minimum number of trades required.
//
// Logic:
// - Returns wins / losses if minimum is met.
// - Prevents division by zero.
// ---------------------------------------------------------------------
double CustomMax::win_loss_ratio(int min_required_trades) {
    double wins = TesterStatistics(STAT_PROFIT_TRADES); 
    double losses = TesterStatistics(STAT_LOSS_TRADES); 
    double total_trades = TesterStatistics(STAT_TRADES); 

    if ((min_required_trades > 0 && total_trades < min_required_trades) || total_trades == 0)
        return 0;
    if (losses == 0)
        return 0;

    return wins / losses;
}

// ---------------------------------------------------------------------
// Calculates win percentage with a minimum trade count check.
//
// Parameters:
// - min_required_trades : Minimum number of trades required.
//
// Logic:
// - Returns (wins / total) * 100 if minimum is met.
// - Filters out invalid math results.
// ---------------------------------------------------------------------
double CustomMax::win_percent_min_trades(int min_required_trades) {
    double wins = TesterStatistics(STAT_PROFIT_TRADES); 
    double total_trades = TesterStatistics(STAT_TRADES); 

    if ((min_required_trades > 0 && total_trades < min_required_trades) || total_trades == 0)
        return 0;

    double result = (wins / total_trades) * 100;
    if (!MathIsValidNumber(result))
        return 0;

    return result;
}
