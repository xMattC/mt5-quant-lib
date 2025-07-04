#include <Trade/Trade.mqh>
#include <MyLibs/Orders/CalculatePositionData.mqh>

class EntryOrders {

   protected:
      CTrade trade;
      CalculatePositionData calc;
      double stop_loss;
      double take_profit;
      int total_open_buy_orders;
      int total_open_sell_orders;
      double current_price;

      int count_open_positions(string symbol, int order_side, long magic_number);

   public:
      bool open_buy_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var,string _tp_mode, double tp_var, string _lot_mode, double lot_var, long magic_number);
      bool open_sell_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var, long magic_number);
      bool open_buy_stop_order(string symbol, bool condition, double entry_price, datetime experation,ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var, long magic_number);
      bool open_sell_stop_order(string symbol, bool condition, double entry_price, datetime experation,ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode, double tp_var,string _lot_mode, double lot_var, long magic_number);
};


int EntryOrders::count_open_positions(string symbol, int order_side, long magic_number) {
   int count = 0;
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (PositionGetString(POSITION_SYMBOL) == symbol &&
          PositionGetInteger(POSITION_MAGIC) == magic_number) {
         if ((order_side == 1 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ||
             (order_side == 2 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)) {
            count++;
         }
      }
   }
   return count;
}

bool EntryOrders::open_buy_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode,
                                  double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,
                                  long magic_number) {
   if (condition) {
      current_price = SymbolInfoDouble(symbol, SYMBOL_ASK);
      total_open_buy_orders = count_open_positions(symbol, 1, magic_number);
      if (total_open_buy_orders == 0) {
         stop_loss = calc.calculate_stoploss(symbol, current_price, 1, _sl_mode, sl_var, atr_period);
         take_profit = calc.calculate_take_profit(symbol, current_price, stop_loss, 1, _tp_mode, tp_var, atr_period);
         double sl_distance = current_price - stop_loss;
         double lots = calc.calculate_lots(symbol, sl_distance, current_price, _lot_mode, lot_var);
         trade.SetExpertMagicNumber(magic_number);
         string comment = "Magic Number: " + IntegerToString(magic_number);
         trade.PositionOpen(symbol, ORDER_TYPE_BUY, lots, current_price, stop_loss, take_profit, comment);
      }
   }
   return true;
}

bool EntryOrders::open_sell_orders(string symbol, bool condition, ENUM_TIMEFRAMES atr_period, string _sl_mode,
                                   double sl_var, string _tp_mode, double tp_var, string _lot_mode, double lot_var,
                                   long magic_number) {
   if (condition) {
      current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
      total_open_sell_orders = count_open_positions(symbol, 2, magic_number);
      if (total_open_sell_orders == 0) {
         stop_loss = calc.calculate_stoploss(symbol, current_price, 2, _sl_mode, sl_var, atr_period);
         take_profit = calc.calculate_take_profit(symbol, current_price, stop_loss, 2, _tp_mode, tp_var, atr_period);
         double sl_distance = stop_loss - current_price;
         double lots = calc.calculate_lots(symbol, sl_distance, current_price, _lot_mode, lot_var);
         trade.SetExpertMagicNumber(magic_number);
         string comment = "Magic Number: " + IntegerToString(magic_number);
         trade.PositionOpen(symbol, ORDER_TYPE_SELL, lots, current_price, stop_loss, take_profit, comment);
      }
   }
   return true;
}

bool EntryOrders::open_buy_stop_order(string symbol, bool condition, double entry_price, datetime experation,
                                      ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode,
                                      double tp_var, string _lot_mode, double lot_var, long magic_number) {
   if (condition) {
      total_open_buy_orders = count_open_positions(symbol, 1, magic_number);
      if (total_open_buy_orders == 0) {
         stop_loss = calc.calculate_stoploss(symbol, entry_price, 1, _sl_mode, sl_var, atr_period);
         take_profit = calc.calculate_take_profit(symbol, entry_price, stop_loss, 1, _tp_mode, tp_var, atr_period);
         double sl_distance = entry_price - stop_loss;
         double lots = calc.calculate_lots(symbol, sl_distance, entry_price, _lot_mode, lot_var);
         trade.SetExpertMagicNumber(magic_number);
         string comment = "Magic Number: " + IntegerToString(magic_number);
         trade.BuyStop(lots, entry_price, symbol, stop_loss, take_profit, ORDER_TIME_SPECIFIED, experation, comment);
      }
   }
   return true;
}

bool EntryOrders::open_sell_stop_order(string symbol, bool condition, double entry_price, datetime experation,
                                       ENUM_TIMEFRAMES atr_period, string _sl_mode, double sl_var, string _tp_mode,
                                       double tp_var, string _lot_mode, double lot_var, long magic_number) {
   if (condition) {
      total_open_sell_orders = count_open_positions(symbol, 2, magic_number);
      if (total_open_sell_orders == 0) {
         stop_loss = calc.calculate_stoploss(symbol, entry_price, 2, _sl_mode, sl_var, atr_period);
         take_profit = calc.calculate_take_profit(symbol, entry_price, stop_loss, 2, _tp_mode, tp_var, atr_period);
         double sl_distance = stop_loss - entry_price;
         double lots = calc.calculate_lots(symbol, sl_distance, entry_price, _lot_mode, lot_var);
         trade.SetExpertMagicNumber(magic_number);
         string comment = "Magic Number: " + IntegerToString(magic_number);
         trade.SellStop(lots, entry_price, symbol, stop_loss, take_profit, ORDER_TIME_SPECIFIED, experation, comment);
      }
   }
   return true;
}
