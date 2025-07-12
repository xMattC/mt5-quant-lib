//+------------------------------------------------------------------+
//|                                              DrawdownControl.mqh |
//|                                                           xMattC |
//+------------------------------------------------------------------+
#property library
#include <Trade/Trade.mqh>
#include <MyLibs/MyFunctions.mqh>

class DrawdownControl : public CObject {
  protected:
      CTrade trade;
      MyFunctions mf;

      string data_file;
      double daily_max_dd_per;
      string daily_reset_time;
      bool   print_statments;

      double acc_max_dd_per;
      double equaty_control_high;
      double equaty_control_low;


      double daily_equity_start;
      double daily_max_dd_target;
      bool   daily_dd_limit_reached;

      bool write_global_var_data();
      bool print_messages();

  public:
      void    init_dd_control(string inp_data_file,  double inp_acc_max_dd_per, double inp_daily_max_dd_per, string inp_daily_reset_time, bool inp_print_statments = true);
      bool    determine_daily_dd_limit();
      double  lot_correction_factor(double acc_equity_start, double min_lot_factor, double max_lot_factor, bool dynm_lot_factor=false, double dlf_trail_per=20);
      double  lot_correction_dynamic(double acc_dd_percent, double min_lot_factor, double max_lot_factor);
};

void DrawdownControl::init_dd_control(string inp_data_file, double inp_acc_max_dd_per, double inp_daily_max_dd_per, string inp_daily_reset_time, bool inp_print_statments = true) {

   data_file         = inp_data_file;
   acc_max_dd_per    = inp_acc_max_dd_per;   
   daily_max_dd_per  = inp_daily_max_dd_per;
   daily_reset_time  = inp_daily_reset_time;
   print_statments   = inp_print_statments;

    // If no data file exisits, create one and set global vairiables:
    if(FileIsExist(data_file) == false) {
         daily_equity_start     = AccountInfoDouble(ACCOUNT_EQUITY);
         daily_max_dd_target    = daily_equity_start - (daily_equity_start * (daily_max_dd_per / 100));
         daily_dd_limit_reached = false;
         equaty_control_high = 9999999;
         equaty_control_low = 0;        
         write_global_var_data();
    }
    // If file exisits read file:
    if(FileIsExist(data_file) == true) {

        int file_handle = FileOpen(data_file, FILE_READ | FILE_ANSI | FILE_TXT);
        if(file_handle == INVALID_HANDLE) {
            Print("Error opening file: ", data_file);
        }

        // If data file is older than 24h 10min create a new file and reset global vars:
        long modifided_date = FileGetInteger(file_handle, FILE_MODIFY_DATE);
        long time_delta     = ((long)TimeCurrent() - modifided_date) / 60;

        if(time_delta >= 1450) {
            daily_equity_start     = AccountInfoDouble(ACCOUNT_EQUITY);
            daily_max_dd_target    = daily_equity_start - (daily_equity_start * (daily_max_dd_per / 100));
            daily_dd_limit_reached = false;
            equaty_control_high = equaty_control_high;
            equaty_control_low = equaty_control_low;                
            write_global_var_data();
            Print(data_file, " is older than 24h and 10min; global vars reset!");
        }
        // If data file is younger than 24h+10 min read data and set global vars:
        else {
            daily_equity_start     = (double)FileReadString(file_handle, 0);
            daily_max_dd_target    = (double)FileReadString(file_handle, 1);
            daily_dd_limit_reached = FileReadBool(file_handle);
            equaty_control_high = (double)FileReadString(file_handle, 3);
            equaty_control_low = (double)FileReadString(file_handle, 4);;                
        }
        FileClose(file_handle);
    }
    print_messages();
}

bool DrawdownControl::determine_daily_dd_limit() {

    // Reset max equity at the start of each day:
    string ct = TimeToString(TimeCurrent(), TIME_MINUTES);
    if(ct == daily_reset_time) {
        daily_equity_start     = AccountInfoDouble(ACCOUNT_EQUITY);
        daily_max_dd_target    = (daily_equity_start - (daily_equity_start * (daily_max_dd_per / 100)));
        daily_dd_limit_reached = false;
        write_global_var_data();
        print_messages();
    }

    // If in drawdown close all positions and delete orders
    if(daily_dd_limit_reached || AccountInfoDouble(ACCOUNT_EQUITY) <= daily_max_dd_target) {

        if(daily_dd_limit_reached == false) {
            daily_dd_limit_reached = true;
            write_global_var_data();
            print_messages();
        }

        for(int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }

        for(int i = OrdersTotal() - 1; i >= 0; i--) {
            ulong ticket = OrderGetTicket(i);
            trade.OrderDelete(ticket);
        }
    }
    return daily_dd_limit_reached;
}

// Reduces lot size as account apporchaes max allowed drawdown limit. 
double DrawdownControl::lot_correction_factor(double acc_equity_start, double min_lot_factor, double max_lot_factor, bool dynm_lot_factor=false, double dlf_trail_per=20) {

   double account_value = fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE));
   double lot_factor;

   // Interpolate to find lot factor between given min and max values.
   if (account_value < acc_equity_start){
     
      double acc_equity_min = acc_equity_start - (acc_equity_start * (acc_max_dd_per / 100));
      double y1  = min_lot_factor;
      double y2  = max_lot_factor;
      double x1  = acc_equity_min;
      double x   = account_value;
      double x2  = acc_equity_start;
      lot_factor = y1 + (x - x1) * ((y2 - y1) / (x2 - x1));
   }

   else if(account_value >= acc_equity_start) {
      
      if(dynm_lot_factor=true){
         lot_factor = lot_correction_dynamic(dlf_trail_per, min_lot_factor, max_lot_factor);
      }

      else {
         lot_factor = max_lot_factor;
      }
   }
   return max_lot_factor;
}


double DrawdownControl::lot_correction_dynamic(double acc_dd_percent, double min_lot_factor, double max_lot_factor) {

   double account_value = fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE));
   double trail_point = account_value - (account_value * (acc_dd_percent / 100));
   
   if(equaty_control_low < trail_point){
      equaty_control_low = trail_point;
   }

   if(equaty_control_high < account_value){
      equaty_control_high = account_value;
   }

   if(account_value < equaty_control_low){
      equaty_control_low = account_value;
      equaty_control_high = account_value + (account_value * (acc_dd_percent / 100));               
   }

   // back-up to file every hour:
   if(mf.is_new_bar(_Symbol, PERIOD_H1) == true){
      write_global_var_data();
   }

   // Linear interpolation:   
   double y1  = min_lot_factor; 
   double y2  = max_lot_factor;
   double x1  = equaty_control_low;
   double x   = account_value;
   double x2  = equaty_control_high;

   double y = y1 + (x - x1) * ((y2 - y1) / (x2 - x1));

   return y;
}

bool DrawdownControl::write_global_var_data() {
    int file_handle = FileOpen(data_file, FILE_WRITE | FILE_ANSI | FILE_TXT);
    FileWrite(file_handle, daily_equity_start);
    FileWrite(file_handle, daily_max_dd_target);
    FileWrite(file_handle, daily_dd_limit_reached);
    FileClose(file_handle);
    Print(data_file, " written");
    return true;
}

bool DrawdownControl::print_messages() {
    if(print_statments == true) {
        Print("TimeCurrent(): ", TimeToString(TimeCurrent()));
        Print("Daily Equity Start:   ", (int)daily_equity_start);
        Print("Current Equity:       ", (int)AccountInfoDouble(ACCOUNT_EQUITY));
        Print("Daily Drawdown Limit: ", (int)daily_max_dd_target, " (", daily_max_dd_per, "%) of DES");
        Print("Daily Drawdown Limit Hit: ", daily_dd_limit_reached);
    }
    return true;
}
