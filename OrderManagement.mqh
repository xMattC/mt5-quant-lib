#property library
#include <Trade/Trade.mqh>
#include <MyLibs/TimeZones.mqh>
#include <MyLibs/MyEnums.mqh>
#include <MyLibs/CalculatePositionData.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>
#include <MyLibs/Myfunctions.mqh>

class OrderManagment : public CObject{
   
   protected:
      CTrade trade;
      TimeZones tz; 
      CalculatePositionData cpd;
      CPositionInfo  m_position;
      COrderInfo     m_order; 

 
      double   stop_loss; 
      double   take_profit;  
      ulong    posTicket;
      int      time_difference;
      int      total_open_buy_orders;
      int      total_open_sell_orders;
      double   current_price;
      int      total_pos;
      long     position_open_time;
      long     first_allowed_close_time;
      datetime current_bar_open_time;

   public:
      bool     open_buy_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,long magic_number);
      bool     open_sell_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,long magic_number);
      bool     open_nnfx_buy_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,long magic_number);
      bool     open_nnfx_sell_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,long magic_number);
      
      bool     open_buy_stop_order(string symbol, bool condition, double entry_price, datetime experation, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,long magic_number);
      bool     open_sell_stop_order(string symbol, bool condition, double entry_price, datetime experation, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,long magic_number);
      bool     close_buy_orders(string symbol, bool buy_out, int close_bars, ENUM_TIMEFRAMES close_bar_period, long magic_number);
      bool     close_sell_orders(string symbol, bool sell_out, int close_bars, ENUM_TIMEFRAMES close_bar_period, long magic_number);
      bool     first_profitable_close_exit(string symbol, ENUM_TIMEFRAMES close_bar_period, long magic_number);
      bool     daily_timed_exit(string symbol, datetime exit_time, int delay_days, long magic_number);
      bool     daily_timed_profit_exit(string symbol, ENUM_TIMEFRAMES close_bar_period, string exit_time, string tz, int delay_days, long magic_number);
      int      count_all_positions(string symbol, long magic_number);
      int      count_pending_orders(string symbol, ENUM_ORDER_TYPE pendingType, long magic);
      double   sl_specified_value_switch(string _sl_mode, double _inp_sl_var, double value);
      double   tp_specified_value_switch(string _tp_mode, double _inp_tp_var, double value); 
      int      count_open_positions(string symbol,int order_side, long magic_number);
      void     break_even_stop(string symbol, ulong magic_number, int be_trigger_points, int be_puffer);  
      void     nnfx_trailing_stop(string symbol, double sl_var, double tp_var, double atr_value, ulong magic_number);        
   };

bool OrderManagment::open_buy_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var, long magic_number){

   if(condition ==  true){
      current_price = SymbolInfoDouble(symbol, SYMBOL_ASK); // ask for buy side

      total_open_buy_orders = count_open_positions(symbol, 1, magic_number);
      if(total_open_buy_orders == 0){

         stop_loss = cpd.calculate_stoploss(symbol, current_price, 1, _sl_mode, sl_var, atr_period);
         take_profit = cpd.calculate_take_profit(symbol, current_price, stop_loss, 1, _tp_mode, tp_var, atr_period);
   
         double sl_distance = current_price-stop_loss;         
         double lots = cpd.calculate_lots(symbol, sl_distance, current_price, _lot_mode, lot_var);
            
         trade.SetExpertMagicNumber(magic_number);
         string comment = "Magic Number: " + IntegerToString(magic_number);
         trade.PositionOpen(symbol,ORDER_TYPE_BUY,lots,current_price,stop_loss,take_profit,comment);
      }
   }
   return true; 
}


bool OrderManagment::open_sell_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,long magic_number){

   if(condition ==  true){

      // if(!SymbolInfoTick(symbol,currentTick)){Print("FAILED TO GET TICK:", symbol);return false;}
      current_price = SymbolInfoDouble(symbol, SYMBOL_BID);  // bid for sell side

      total_open_sell_orders = count_open_positions(symbol, 2, magic_number);
      if(total_open_sell_orders == 0){

         stop_loss = cpd.calculate_stoploss(symbol, current_price, 2, _sl_mode, sl_var, atr_period);
         take_profit = cpd.calculate_take_profit(symbol, current_price, stop_loss, 2, _tp_mode, tp_var, atr_period);

         double sl_distance = stop_loss-current_price;
         double lots = cpd.calculate_lots(symbol, sl_distance, current_price, _lot_mode, lot_var);

         trade.SetExpertMagicNumber(magic_number);
         string comment = "Magic Number: " + IntegerToString(magic_number);         
         trade.PositionOpen(symbol,ORDER_TYPE_SELL,lots,current_price,stop_loss,take_profit,comment);
      }
   }
   return true; 
}

bool OrderManagment::open_nnfx_buy_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var, long magic_number){

   if(condition ==  true){
      current_price = SymbolInfoDouble(symbol, SYMBOL_ASK); // ask for buy side

      total_open_buy_orders = count_open_positions(symbol, 1, magic_number);
      if(total_open_buy_orders == 0){

         stop_loss = cpd.calculate_stoploss(symbol, current_price, 1, _sl_mode, sl_var, atr_period);
         take_profit = cpd.calculate_take_profit(symbol, current_price, stop_loss, 1, _tp_mode, tp_var, atr_period);
   
         double sl_distance = current_price-stop_loss;         
         double lots = cpd.calculate_lots(symbol, sl_distance, current_price, _lot_mode, lot_var/2);
            
         trade.SetExpertMagicNumber(magic_number);
         string comment = "Magic Number: " + IntegerToString(magic_number);
         trade.PositionOpen(symbol,ORDER_TYPE_BUY,lots,current_price,stop_loss,take_profit,comment);
         trade.PositionOpen(symbol,ORDER_TYPE_BUY,lots,current_price,stop_loss,0,comment);
      }
   }
   return true; 
}


bool OrderManagment::open_nnfx_sell_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,long magic_number){

   if(condition ==  true){

      // if(!SymbolInfoTick(symbol,currentTick)){Print("FAILED TO GET TICK:", symbol);return false;}
      current_price = SymbolInfoDouble(symbol, SYMBOL_BID);  // bid for sell side

      total_open_sell_orders = count_open_positions(symbol, 2, magic_number);
      if(total_open_sell_orders == 0){

         stop_loss = cpd.calculate_stoploss(symbol, current_price, 2, _sl_mode, sl_var, atr_period);
         take_profit = cpd.calculate_take_profit(symbol, current_price, stop_loss, 2, _tp_mode, tp_var, atr_period);

         double sl_distance = stop_loss-current_price;
         double lots = cpd.calculate_lots(symbol, sl_distance, current_price, _lot_mode, lot_var);

         trade.SetExpertMagicNumber(magic_number);
         string comment = "Magic Number: " + IntegerToString(magic_number);         
         trade.PositionOpen(symbol,ORDER_TYPE_SELL,lots,current_price,stop_loss,take_profit,comment);
         trade.PositionOpen(symbol,ORDER_TYPE_SELL,lots,current_price,stop_loss,0,comment);         
      }
   }
   return true; 
}
// some usfull comment here
bool OrderManagment::open_buy_stop_order(string symbol, bool condition, double entry_price, datetime experation, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var,string _tp_mode, double tp_var, string _lot_mode, double lot_var,long magic_number){

   if(condition ==  true){

      total_open_buy_orders = count_open_positions(symbol, 1, magic_number);
      if(total_open_buy_orders == 0){

         stop_loss = cpd.calculate_stoploss(symbol, entry_price, 1, _sl_mode, sl_var, atr_period);
         take_profit = cpd.calculate_take_profit(symbol, entry_price, stop_loss, 1, _tp_mode, tp_var, atr_period);

         double sl_distance = entry_price-stop_loss;          
         double lots = cpd.calculate_lots(symbol, sl_distance, entry_price, _lot_mode, lot_var);
            
         trade.SetExpertMagicNumber(magic_number);
         string comment = "Magic Number: " + IntegerToString(magic_number);
         trade.BuyStop(lots, entry_price, symbol, stop_loss, take_profit, ORDER_TIME_SPECIFIED, experation, comment);
      }
   }
   return true; 
}


bool OrderManagment::open_sell_stop_order(string symbol, bool condition, double entry_price, datetime experation,  ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,long magic_number){

   if(condition ==  true){

      total_open_sell_orders = count_open_positions(symbol, 2, magic_number);
      if(total_open_sell_orders == 0){

         stop_loss = cpd.calculate_stoploss(symbol, entry_price, 2, _sl_mode, sl_var, atr_period);
         take_profit = cpd.calculate_take_profit(symbol, entry_price, stop_loss, 2, _tp_mode, tp_var, atr_period);
 
         double sl_distance = stop_loss-entry_price;
         double lots = cpd.calculate_lots(symbol, sl_distance, entry_price, _lot_mode, lot_var);

         trade.SetExpertMagicNumber(magic_number);
         string comment = "Magic Number: " + IntegerToString(magic_number);         
         trade.SellStop(lots, entry_price, symbol, stop_loss, take_profit, ORDER_TIME_SPECIFIED, experation, comment);
      }
   }
   return true; 
}

bool OrderManagment::close_buy_orders(string symbol, bool condition, int close_bars, ENUM_TIMEFRAMES close_bar_period, long magic_number){

   for(int i = PositionsTotal()-1; i >=0; i--){
      posTicket = PositionGetTicket(i);
      
      if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magic_number){
         
         time_difference = Bars(symbol, close_bar_period, PositionGetInteger(POSITION_TIME), TimeCurrent()) - 1;      

         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){           

            if(condition){
               trade.PositionClose(posTicket);
            }

            if(close_bars > 0){
               if(time_difference >= close_bars){
                  trade.PositionClose(posTicket);
               }
            }
         }
      }
   } 
   return true;
}

bool OrderManagment::close_sell_orders(string symbol, bool condition, int close_bars, ENUM_TIMEFRAMES close_bar_period, long magic_number){

   for(int i = PositionsTotal()-1; i >=0; i--){
      posTicket = PositionGetTicket(i);
      
      if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magic_number){
         
         time_difference = Bars(symbol, close_bar_period, PositionGetInteger(POSITION_TIME), TimeCurrent()) - 1;     

         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){           

            if(condition){trade.PositionClose(posTicket);}

            if(close_bars > 0){
               if(time_difference >= close_bars){
                  trade.PositionClose(posTicket);
               }
            }
         }
      }
   } 
   return true;
}

// order_side int must be 1 for BUY or 2 for SELL
int OrderManagment::count_open_positions(string symbol,int order_side, long magic_number){

    
   int count = 0;
   bool match = (PositionGetInteger(POSITION_MAGIC)==magic_number);

   for(int i = PositionsTotal()-1; i >=0; i--){
      ulong ticket = PositionGetTicket(i);

      if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC)==magic_number){

         // Count only Buy orders: 
         if(order_side == 1){
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
            count = count + 1;
            }
        }
         
         // Count only Sell orders:
         if(order_side == 2){
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
            count = count + 1;
            }
        }
      }
   }   
   return count;
}

int OrderManagment::count_all_positions(string symbol, long magic_number){
    
   int count = 0;
   for(int i = PositionsTotal()-1; i >=0; i--){
      ulong ticket = PositionGetTicket(i);

      if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC)==magic_number){
         count = count + 1;
      }
   }   
   return count;
}

bool OrderManagment::daily_timed_exit(string symbol, datetime exit_time, int delay_days, long magic_number){

   for(int i = PositionsTotal()-1; i >=0; i--){
      posTicket = PositionGetTicket(i);
      position_open_time = PositionGetInteger(POSITION_TIME);

      if((int)position_open_time>0){

         first_allowed_close_time = position_open_time + (delay_days * PeriodSeconds(PERIOD_D1));
         if(TimeCurrent() > first_allowed_close_time){

            // datetime broker_close_time = tz.timezone_conversions(cw_tzone, StringToTime(exit_time), "Broker");
            if(TimeCurrent()>= exit_time){

               if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magic_number){

                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                           trade.PositionClose(posTicket);
                  }
                  
                  // Sell orders:
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                        trade.PositionClose(posTicket);
                  }
               }
            }
         }
      }
   }
return true;
}

bool OrderManagment::daily_timed_profit_exit(string symbol, ENUM_TIMEFRAMES close_bar_period, string exit_time, string cw_tzone, int delay_days, long magic_number){

   // om.daily_timed_profit_exit(_Symbol, PERIOD_CURRENT, "16:45", "17:00", "NY", 1, inp_magic);

   for(int i = PositionsTotal()-1; i >=0; i--){
      posTicket = PositionGetTicket(i);
      position_open_time = PositionGetInteger(POSITION_TIME);

      if((int)position_open_time>0){

         first_allowed_close_time = position_open_time + (delay_days * PeriodSeconds(PERIOD_D1));
         if(TimeCurrent() > first_allowed_close_time){


            datetime broker_close_time = tz.timezone_conversions(cw_tzone, StringToTime(exit_time), "Broker");
            if(TimeCurrent()>= broker_close_time){

               if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magic_number){
                  
                  double position_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
                  double spread = SymbolInfoDouble(symbol,SYMBOL_ASK) - SymbolInfoDouble(symbol,SYMBOL_BID);       
                  double bar_close = iClose(_Symbol, close_bar_period, 1); // shift 1 because 0 = live candle.
                  double trading_cost = cpd.calculate_trading_cost(symbol, posTicket);


                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                     if(bar_close  > (position_open_price + spread + trading_cost)){                        
                           trade.PositionClose(posTicket);
                           
                     }
                  }
                  
                  // Sell orders:
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                     if(bar_close < position_open_price - spread - trading_cost){
                        trade.PositionClose(posTicket);
                     }
                  }
               }
            }
         }
      }
   }
return true;
}


bool OrderManagment::first_profitable_close_exit(string symbol, ENUM_TIMEFRAMES close_bar_period, long magic_number){
   // om.first_profitable_close_exit(_Symbol, PERIOD_CURRENT, inp_magic);

   position_open_time = PositionGetInteger(POSITION_TIME);
   first_allowed_close_time = position_open_time + PeriodSeconds(close_bar_period);

   if((int)position_open_time>0){
      
      if(TimeCurrent() > first_allowed_close_time){
         for(int i = PositionsTotal()-1; i >=0; i--){
            posTicket = PositionGetTicket(i);

            if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magic_number){
               
               double position_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
               double spread = SymbolInfoDouble(symbol,SYMBOL_ASK) - SymbolInfoDouble(symbol,SYMBOL_BID);       
               double bar_close = iClose(_Symbol,close_bar_period, 1); // shift 1 because 0 = live candle.
               double trading_cost = cpd.calculate_trading_cost(symbol, posTicket);


               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                  if(bar_close  > (position_open_price + spread + trading_cost)){                        
                        trade.PositionClose(posTicket);
                        
                  }
               }
               
               // Sell orders:
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                  if(bar_close < position_open_price - spread - trading_cost){
                     trade.PositionClose(posTicket);
                  }
               }
            }
         }
      }
   }
return true;
}

// e.g. int buy_stop_count = om.count_pending_orders(symbol, ORDER_TYPE_BUY_STOP, inp_magic);
// order types: ORDER_TYPE_BUY_LIMIT, ORDER_TYPE_SELL_LIMIT, ORDER_TYPE_BUY_STOP, ORDER_TYPE_SELL_STOP
int OrderManagment::count_pending_orders(string symbol, ENUM_ORDER_TYPE order_type, long magic){
   int count = 0;

    for(int i=OrdersTotal()-1;i>=0;i--) {

        if(m_order.SelectByIndex(i)){
            if( OrderGetInteger(ORDER_MAGIC) == magic && OrderGetString(ORDER_SYMBOL) == symbol){

                if(m_order.OrderType()==order_type){
                    count++;
                }
            }
        }
    }
    return(count);
}

void OrderManagment::break_even_stop(string symbol, ulong magic_number, int be_trigger_points, int be_puffer){

   for(int i = PositionsTotal()-1; i >=0; i--){
      if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magic_number){

         int symbol_digits  = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
         double symbol_point  = SymbolInfoDouble(symbol, SYMBOL_POINT);

         double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
         ask = NormalizeDouble(ask, symbol_digits);
         
         double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
         bid = NormalizeDouble(bid, symbol_digits);

         if(be_trigger_points !=0){

            
            ulong ticket = PositionGetTicket(i);
            if(PositionSelectByTicket(ticket)){

               double position_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
               double position_volume = PositionGetDouble(POSITION_VOLUME);
               double position_sl = PositionGetDouble(POSITION_SL);
               double position_tp = PositionGetDouble(POSITION_TP); 
               ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

               if(position_type == POSITION_TYPE_BUY){
                  
                  if(bid > position_open_price + be_trigger_points * symbol_point){

                     double sl = position_open_price + be_puffer * symbol_point;
                     sl = NormalizeDouble(sl, symbol_digits);
                     if(sl > position_sl){
                        
                        if(trade.PositionModify(ticket, sl, position_tp)){
                           Print("-----------------------------------Stop moved to break even");
                        }
                     }
                  }
               }
               else if(position_type == POSITION_TYPE_SELL){
                  
                  if(ask < position_open_price - be_trigger_points * symbol_point){

                     double sl = position_open_price - be_puffer * symbol_point;
                     sl = NormalizeDouble(sl, symbol_digits);
                     if(sl < position_sl){
                        
                        if(trade.PositionModify(ticket, sl, position_tp)){
                           Print("-----------------------------------Stop moved to break even");
                        }
                     }
                  }
               }
            }
         }
      }
   }
}


void OrderManagment::nnfx_trailing_stop(string symbol, double sl_var, double tp_var, double atr_value, ulong magic_number){

   MyFunctions mf3;

   for(int i = PositionsTotal()-1; i >=0; i--){

      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)){

         if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magic_number){

            int symbol_digits  = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
            double symbol_point  = SymbolInfoDouble(symbol, SYMBOL_POINT);

            double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
            ask = NormalizeDouble(ask, symbol_digits);
            
            double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
            bid = NormalizeDouble(bid, symbol_digits);

            double position_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
            double position_sl = PositionGetDouble(POSITION_SL);
            double position_tp = PositionGetDouble(POSITION_TP); 
            ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

            if(position_type == POSITION_TYPE_BUY){

               if(bid > position_open_price + (atr_value * tp_var)){

                  double sl = bid - (atr_value * sl_var);
                  sl = NormalizeDouble(sl, symbol_digits);
                  if(sl > (position_sl + (atr_value * 0.5))){

                     if(trade.PositionModify(ticket, sl, position_tp)){

                     }
                  }
               }
            }
            

            else if(position_type == POSITION_TYPE_SELL){
            
               if(ask < position_open_price - (atr_value * tp_var)){

                  double sl = ask + (atr_value * sl_var);
                  sl = NormalizeDouble(sl, symbol_digits);
                  if(sl < (position_sl + (atr_value * 0.5))){

                     if(trade.PositionModify(ticket, sl, position_tp)){
                     }
                  }
               }
            }
         }
      }


   }
}

double OrderManagment::sl_specified_value_switch(string _sl_mode, double _inp_sl_var, double value){
    double sl = 0;
    if(_sl_mode=="SL_SPECIFIED_VALUE"){sl = value;}
    if(_sl_mode!="SL_SPECIFIED_VALUE"){sl = _inp_sl_var;}
    return sl;
}
double OrderManagment::tp_specified_value_switch(string _tp_mode, double _inp_tp_var, double value){
    double tp = 0;
    if(_tp_mode=="SL_SPECIFIED_VALUE"){tp = value;}
    if(_tp_mode!="SL_SPECIFIED_VALUE"){tp = _inp_tp_var;}
    return tp;
}