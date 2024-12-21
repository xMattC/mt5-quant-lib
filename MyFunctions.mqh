#property library
#include <Trade/Trade.mqh>
#include <MyLibs/TradingWindow.mqh>
#include <MyLibs/MyEnums.mqh>

class MyFunctions : public CObject{

   protected:
      CTrade trade;
      TradingWindow tw;      
      datetime previousTime;
      datetime bar_open_time;

   public:
      void     draw_line(double value, string name,color clr);
      bool     check_indicator_handles(int &indicator_handles[]);
      double   adjusted_point(string symbol);
      double   get_bid_ask_price(string symbol, int price_side);
      bool     is_new_bar(string symbol, ENUM_TIMEFRAMES time_frame, string daily_start_time="00:10");   
      bool     trade_window(string t1, string t2, string time_zone, bool plot_range_inp=true);
      bool     in_test_period(MODE_SPLIT_DATA data_period);
      void     get_white_list(MULTI_SYM_MODE mode, string& DataArray[]);
};

void MyFunctions::get_white_list(MULTI_SYM_MODE mode, string& DataArray[]){

    if(mode==MULTI_SYM_CHART){
        string a[] = {_Symbol};        
        ArrayResize(DataArray, ArraySize(a));
        for(int i = 0; i < ArraySize(DataArray); i++){    
            DataArray[i]=a[i];
        }
    }    
    if(mode==MULTI_SYM_FX_B5){
        string a[] = {"EURUSD", "AUDNZD", "EURGBP", "AUDCAD", "CHFJPY"};        
        ArrayResize(DataArray, ArraySize(a));
        for(int i = 0; i < ArraySize(DataArray); i++){    
            DataArray[i]=a[i];
        }
    }
    if(mode==MULTI_SYM_FX_28){
        string a[] = {"EURUSD","AUDNZD","AUDUSD","AUDJPY","EURCHF","EURGBP","EURJPY","GBPCHF","GBPJPY","GBPUSD","NZDUSD","USDCAD","USDCHF","USDJPY","CADJPY","EURAUD","CHFJPY","EURCAD","AUDCAD","AUDCHF","CADCHF","EURNZD","GBPAUD","GBPCAD","GBPNZD","NZDCAD","NZDCHF","NZDJPY",};        
        ArrayResize(DataArray, ArraySize(a));
        for(int i = 0; i < ArraySize(DataArray); i++){    
            DataArray[i]=a[i];
        }
    }    
}

bool MyFunctions::trade_window(string t1, string t2, string time_zone="Broker", bool plot_range_inp=true){
   bool in_window = tw.define_window(t1, t2, time_zone, plot_range_inp);
   return in_window;
}

//if(!mf.is_new_bar(symbol, PERIOD_D1, "00:06")){return;}
bool MyFunctions::is_new_bar(string symbol, ENUM_TIMEFRAMES time_frame, string daily_start_time="00:10"){
   
   bar_open_time = iTime(symbol, time_frame, 0);
   if(previousTime!=bar_open_time){     
      
      if(PeriodSeconds(time_frame)==PeriodSeconds(PERIOD_D1)){   
         if(TimeCurrent() > StringToTime(daily_start_time)){
            previousTime=bar_open_time;
            return true;            
         }
      }
      
      else{
         previousTime=bar_open_time;         
         return true;                    
      }

   }
   return false;
}

//if(!mf.in_test_period(data_split_method){return;}
bool MyFunctions::in_test_period(MODE_SPLIT_DATA data_split_method){

   string result[];
   string string_tc = TimeToString(TimeCurrent());
   ushort u_sep = StringGetCharacter(".",0); 
   int split_string = StringSplit(string_tc, u_sep, result); 
   bool odd_year = int(result[0]) % 2;
   bool odd_month = int(result[1]) % 2;  

   // get week of the year. rough estimate can be late the first week of jan:
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt); 
   int iDay  = (dt.day_of_week + 6 ) % 7 + 1;        // convert day to standard index (1=Mon,...,7=Sun)
   int iWeek = (dt.day_of_year - iDay + 10 ) / 7;    // calculate standard week number
   
   bool odd_week = iWeek % 2;     


   if(data_split_method==NO_SPLIT){
      return true;
   }

   if(data_split_method==ODD_YEARS){
      if (odd_year){              
         return true;
      }
   }

   if(data_split_method==EVEN_YEARS){
      if (!odd_year){      
         return true;
      }
   }

   if(data_split_method==ODD_MONTHS){
      if (odd_month){   
         return true;
      }
   }

   if(data_split_method==EVEN_MONTHS){

      if (!odd_month){
         return true;
      }
   }

   if(data_split_method==ODD_WEEKS){
      if (odd_week){     
         return true;
      }
   }

   if(data_split_method==EVEN_WEEKS){

      if (!odd_week){
         return true;
      }
   }

   return false;
}

void MyFunctions::draw_line(double value, string name,color clr=clrBlack){
   // EG:
   //    ArrayResize(bar,1000);
   //    ArraySetAsSeries(bar, true);
   //    CopyRates(symbol,PERIOD_CURRENT,1,1000,bar);
   //    double close = bar[0].close;  
   //    draw_line(close,"CLOSE",clrBlue);

   if(ObjectFind(0,name)<0){
      ResetLastError();

      if(!ObjectCreate(0,name,OBJ_HLINE,0,0,value)){
         Print(__FUNCTION__,": failed to create a horizontal line! Error code = ",GetLastError());
         return;
      }

      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
      ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
   }

   ResetLastError();

   if(!ObjectMove(0,name,0,0,value)){
      Print(__FUNCTION__,": failed to move the horizontal line! Error code = ",GetLastError());
      return;
   }
   
   ChartRedraw();
}

double MyFunctions::adjusted_point(string symbol){

   int symbol_digits  = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   int digits_adjust=1;
   if(symbol_digits==3 || symbol_digits==5){
      digits_adjust=10;
   }

   double symbol_point_val = SymbolInfoDouble(symbol,SYMBOL_POINT);
   double m_adjusted_point;
   m_adjusted_point = symbol_point_val * digits_adjust;

   return m_adjusted_point;

}
// price side - 1 for the ask price and 2 for the bid price
double MyFunctions::get_bid_ask_price(string symbol, int price_side){

   int symbol_digits  = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double symbol_point  = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   ask = NormalizeDouble(ask, symbol_digits);
   
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   bid = NormalizeDouble(bid, symbol_digits);
   
   double price = 0;
   
   if(price_side==1){
      price =  ask;
   }
   
   else if(price_side==2){
      price =  bid;
   }

   return price;

}