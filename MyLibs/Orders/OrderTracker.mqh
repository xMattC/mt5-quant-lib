//+------------------------------------------------------------------+
//|                                                OrderTracker.mqh  |
//|                          Tracks open orders or pending positions |
//|                                                                  |
//|                                  2025 xMattC (github.com/xMattC) |
//+------------------------------------------------------------------+
#property copyright "2025 xMattC (github.com/xMattC)"
#property link      "https://github.com/xMattC"
#property version   "1.00"

#include <Trade/OrderInfo.mqh>
#include <Trade/PositionInfo.mqh>

class OrderTracker {
   protected:
    COrderInfo m_order;
    CPositionInfo m_position;

   public:
    int count_open_positions(string symbol, int order_side, long magic_number);
    int count_pending_orders(string symbol, ENUM_ORDER_TYPE order_type, long magic);
};


// ---------------------------------------------------------------------
// Counts open positions by symbol, side, and magic number.
//
// Parameters:
// - symbol        : Symbol to check.
// - order_side    : 1 = Buy, 2 = Sell, 0 = Any.
// - _magic_number : Magic number to filter.
//
// Returns:
// - Number of matching open positions.
// ---------------------------------------------------------------------
int OrderTracker::count_open_positions(string symbol, int order_side, long _magic_number) {
    int count = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        
        if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == _magic_number) {
            int type = (int) PositionGetInteger(POSITION_TYPE);
            if (order_side == 0 || (order_side == 1 && type == POSITION_TYPE_BUY) || (order_side == 2 && type == POSITION_TYPE_SELL)) {
                count++;
            }
        }
    }
    return count;
}

// ---------------------------------------------------------------------
// Counts pending orders of a specific type for a symbol and magic number.
//
// Parameters:
// - symbol     : Trading symbol.
// - order_type : Type of pending order (e.g., ORDER_TYPE_BUY_STOP).
// - magic      : Magic number identifying strategy group.
//
// Returns:
// - Number of matching pending orders.
// ---------------------------------------------------------------------
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
