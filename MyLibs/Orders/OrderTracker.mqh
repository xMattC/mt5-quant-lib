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


// ---------------------------------------------------------------------
// Counts the number of open BUY or SELL positions for a given symbol.
//
// Parameters:
// - symbol       : Trading symbol (e.g., "EURUSD").
// - order_side   : 1 = BUY, 2 = SELL.
// - magic_number : Magic number identifying strategy group.
//
// Returns:
// - Number of matching open positions.
// ---------------------------------------------------------------------
int OrderTracker::count_open_positions(string symbol, int order_side, long magic_number) {
    int count = 0;

    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);

        if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magic_number) {
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

// ---------------------------------------------------------------------
// Counts all open positions for a symbol regardless of direction.
//
// Parameters:
// - symbol       : Trading symbol.
// - magic_number : Magic number identifying strategy group.
//
// Returns:
// - Total number of matching positions.
// ---------------------------------------------------------------------
int OrderTracker::count_all_positions(string symbol, long magic_number) {
    int count = 0;

    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);

        if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magic_number) {
            count++;
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
