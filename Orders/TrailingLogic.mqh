#include <Trade/Trade.mqh>

class TrailingLogic {

   protected:
      CTrade trade;

   public:
      void break_even_stop(string symbol, ulong magic_number, int be_trigger_points, int be_puffer);
      void nnfx_trailing_stop(string symbol, double sl_var, double tp_var, double atr_value, ulong magic_number);
};


void TrailingLogic::break_even_stop(string symbol, ulong magic_number, int be_trigger_points, int be_puffer) {
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magic_number) {

         int symbol_digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
         double symbol_point = SymbolInfoDouble(symbol, SYMBOL_POINT);
         double ask = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_ASK), symbol_digits);
         double bid = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_BID), symbol_digits);

         if (be_trigger_points != 0) {
            ulong ticket = PositionGetTicket(i);
            if (PositionSelectByTicket(ticket)) {
               double position_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
               double position_volume = PositionGetDouble(POSITION_VOLUME);
               double position_sl = PositionGetDouble(POSITION_SL);
               double position_tp = PositionGetDouble(POSITION_TP);
               ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

               if (position_type == POSITION_TYPE_BUY &&
                   bid > position_open_price + be_trigger_points * symbol_point) {

                  double sl = NormalizeDouble(position_open_price + be_puffer * symbol_point, symbol_digits);
                  if (sl > position_sl) {
                     trade.PositionModify(ticket, sl, position_tp);
                     Print("-----------------------------------Stop moved to break even");
                  }
               }

               if (position_type == POSITION_TYPE_SELL &&
                   ask < position_open_price - be_trigger_points * symbol_point) {

                  double sl = NormalizeDouble(position_open_price - be_puffer * symbol_point, symbol_digits);
                  if (sl < position_sl) {
                     trade.PositionModify(ticket, sl, position_tp);
                     Print("-----------------------------------Stop moved to break even");
                  }
               }
            }
         }
      }
   }
}


void TrailingLogic::nnfx_trailing_stop(string symbol, double sl_var, double tp_var, double atr_value, ulong magic_number) {

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket)) {
         if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magic_number) {

            int symbol_digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
            double symbol_point = SymbolInfoDouble(symbol, SYMBOL_POINT);
            double ask = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_ASK), symbol_digits);
            double bid = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_BID), symbol_digits);

            double position_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
            double position_sl = PositionGetDouble(POSITION_SL);
            double position_tp = PositionGetDouble(POSITION_TP);
            ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

            if (position_type == POSITION_TYPE_BUY &&
                bid > position_open_price + (atr_value * tp_var)) {

               double sl = NormalizeDouble(bid - (atr_value * sl_var), symbol_digits);
               if (sl > (position_sl + (atr_value * 0.5))) {
                  trade.PositionModify(ticket, sl, position_tp);
               }
            }

            if (position_type == POSITION_TYPE_SELL &&
                ask < position_open_price - (atr_value * tp_var)) {

               double sl = NormalizeDouble(ask + (atr_value * sl_var), symbol_digits);
               if (sl < (position_sl + (atr_value * 0.5))) {
                  trade.PositionModify(ticket, sl, position_tp);
               }
            }
         }
      }
   }
}
