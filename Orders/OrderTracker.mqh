#include <Trade/OrderInfo.mqh>
#include <Trade/PositionInfo.mqh>

class OrderTracker {

   protected:
      COrderInfo m_order;
      CPositionInfo m_position;

   public:
      int count_open_positions(string symbol, int order_side, long magic_number);
      int count_all_positions(string symbol, long magic_number);
      int count_pending_orders(string symbol, ENUM_ORDER_TYPE order_type, long magic);
};

int OrderTracker::count_open_positions(string symbol, int order_side, long magic_number) {
   int count = 0;

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);

      if (PositionGetString(POSITION_SYMBOL) == symbol &&
          PositionGetInteger(POSITION_MAGIC) == magic_number) {

         if (order_side == 1 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            count++;
         }

         if (order_side == 2 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            count++;
         }
      }
   }

   return count;
}


int OrderTracker::count_all_positions(string symbol, long magic_number) {
   int count = 0;

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);

      if (PositionGetString(POSITION_SYMBOL) == symbol &&
          PositionGetInteger(POSITION_MAGIC) == magic_number) {
         count++;
      }
   }

   return count;
}


int OrderTracker::count_pending_orders(string symbol, ENUM_ORDER_TYPE order_type, long magic) {
   int count = 0;

   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (m_order.SelectByIndex(i)) {
         if (OrderGetInteger(ORDER_MAGIC) == magic && OrderGetString(ORDER_SYMBOL) == symbol) {
            if (m_order.OrderType() == order_type) {
               count++;
            }
         }
      }
   }

   return count;
}
