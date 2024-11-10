#property library
#include <Trade/Trade.mqh>

enum  CUSTOM_MAX_TYPE{
    CM_WIN_LOSS_RATIO,
    CM_WIN_PERCENT,
    CM_WIN_PERCENT_200T,      
    CM_WIN_PERCENT_300T,  
    CM_WIN_PERCENT_400T,  
    CM_WIN_PERCENT_500T,  
    CM_WIN_PERCENT_600T,  
    CM_WIN_PERCENT_700T,  
    CM_WIN_PERCENT_800T,   
    CM_WIN_PERCENT_900T,  
    CM_WIN_PERCENT_1000T,             
};

class CustomMax : public CObject{
   
    protected:
        double custom_criteria;

        double CustomMax::win_loss_ratio();
        double CustomMax::win_percent();
        double CustomMax::win_percent_min_trades(int min_resuired_trades);

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
        custom_criteria = win_percent_min_trades(200);
    }        
    if(cm_type==CM_WIN_PERCENT_300T){
        custom_criteria = win_percent_min_trades(300);
    }  
    if(cm_type==CM_WIN_PERCENT_400T){
        custom_criteria = win_percent_min_trades(400);
    }  
    if(cm_type==CM_WIN_PERCENT_500T){
        custom_criteria = win_percent_min_trades(500);
    }  
    if(cm_type==CM_WIN_PERCENT_600T){
        custom_criteria = win_percent_min_trades(600);
    }  
    if(cm_type==CM_WIN_PERCENT_700T){
        custom_criteria = win_percent_min_trades(700);
    }  
    if(cm_type==CM_WIN_PERCENT_800T){
        custom_criteria = win_percent_min_trades(800);
    }  
    if(cm_type==CM_WIN_PERCENT_900T){
        custom_criteria = win_percent_min_trades(900);
    }  
    if(cm_type==CM_WIN_PERCENT_1000T){
        custom_criteria = win_percent_min_trades(1000);
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

double CustomMax::win_percent_min_trades(int min_resuired_trades){
    double wins = TesterStatistics(STAT_PROFIT_TRADES); 
    double total_trades = TesterStatistics(STAT_TRADES); 

    if(total_trades<min_resuired_trades){
        return 0;
    }

    else {
        return wins / total_trades * 100;
    }
}