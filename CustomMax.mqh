#property library
#include <Trade/Trade.mqh>

enum  CUSTOM_MAX_TYPE{
    CM_WIN_LOSS_RATIO,
    CM_WIN_PERCENT,
    CM_WIN_PERCENT_200T      
};

class CustomMax : public CObject{
   
    protected:
        double custom_criteria;

        double CustomMax::win_loss_ratio();
        double CustomMax::win_percent();
        double CustomMax::win_percent_min_trades_200();

    public:
        double CustomMax::calculate_custom_criteria(CUSTOM_MAX_TYPE cm_type);

};

// CM_WIN_LOSS_RATIO,
// CM_WIN_PERCENT
double CustomMax::calculate_custom_criteria(CUSTOM_MAX_TYPE cm_type){
    if(cm_type==CM_WIN_LOSS_RATIO){
        custom_criteria = win_loss_ratio();
    }
    if(cm_type==CM_WIN_PERCENT){
        custom_criteria = win_percent();
    }    
    if(cm_type==CM_WIN_PERCENT_200T){
        custom_criteria = win_percent_min_trades_200();
    }        
    return custom_criteria;
}

double CustomMax::win_loss_ratio(){
    double wins = TesterStatistics(STAT_PROFIT_TRADES); 
    double losses = TesterStatistics(STAT_LOSS_TRADES); 
    return wins/losses;
}
 
double CustomMax::win_percent(){
    double wins = TesterStatistics(STAT_PROFIT_TRADES); 
    double total_trades = TesterStatistics(STAT_TRADES); 
    return wins / total_trades * 100;
}

double CustomMax::win_percent_min_trades_200(){
    double wins = TesterStatistics(STAT_PROFIT_TRADES); 
    double total_trades = TesterStatistics(STAT_TRADES); 

    if(total_trades<200){
        return 0;
    }

    else {
        return wins / total_trades * 100;
    }
}