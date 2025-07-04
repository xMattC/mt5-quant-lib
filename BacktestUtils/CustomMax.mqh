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

// Returns the win/loss ratio, with min trades check
double CustomMax::win_loss_ratio(int min_required_trades) {
    double wins = TesterStatistics(STAT_PROFIT_TRADES); 
    double losses = TesterStatistics(STAT_LOSS_TRADES); 
    double total_trades = TesterStatistics(STAT_TRADES); 
    if((min_required_trades > 0 && total_trades < min_required_trades) || total_trades == 0) return 0;
    if(losses == 0) return 0; // Prevent division by zero
    return wins / losses;
}

// Returns the win percentage, with min trades check
double CustomMax::win_percent_min_trades(int min_required_trades) {
    double wins = TesterStatistics(STAT_PROFIT_TRADES); 
    double total_trades = TesterStatistics(STAT_TRADES); 
    if((min_required_trades > 0 && total_trades < min_required_trades) || total_trades == 0) return 0;
    double result = wins / total_trades * 100;
    if(!MathIsValidNumber(result)) return 0;
    return result;
}
