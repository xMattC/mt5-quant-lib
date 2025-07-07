class AdjustPosition {
   public:
    void set_breakeven_sl(string symbol, int runner_magic_no, double buffer_points = 5);
    void set_breakeven_sl_if_tp_crossed(string symbol, int runner_magic_no, double buffer_points = 5);
    void set_fixed_sl(string symbol, int runner_magic_no, double fixed_sl_price);
    void set_trailing_sl(string symbol, int runner_magic_no, double sl_offset_points = 5);

   private:
    void set_breakeven_sl_for_ticket(string symbol, ulong ticket, long order_type, double entry_price, double current_sl, double current_tp,
                                     int digits, double buffer_price, bool remove_tp);
};

// ---------------------------------------------------------

void AdjustPosition::set_breakeven_sl(string symbol, int runner_magic_no, double buffer_points) {
    int digits = (int) SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double buffer_price = buffer_points * _Point;

    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (!PositionSelectByTicket(ticket)) continue;
        if (PositionGetString(POSITION_SYMBOL) != symbol) continue;
        if ((int) PositionGetInteger(POSITION_MAGIC) != runner_magic_no) continue;

        long order_type = PositionGetInteger(POSITION_TYPE);
        double entry = PositionGetDouble(POSITION_PRICE_OPEN);
        double sl = PositionGetDouble(POSITION_SL);
        double tp = PositionGetDouble(POSITION_TP);

        set_breakeven_sl_for_ticket(symbol, ticket, order_type, entry, sl, tp, digits, buffer_price, false);
    }
}

// ---------------------------------------------------------
/**
 * Check runner trades for virtual take-profit hits and set SL to breakeven if crossed.
 *
 * Runner trades are assumed to be opened with no TP and a special comment in the format: "runner_tp:1.10500".
 * This method parses that comment to determine the virtual TP, and if price has crossed it, moves SL to breakeven ± buffer.
 *
 * param symbol: Trading symbol to check positions for
 * param runner_magic_no: Magic number assigned to runner trades
 * param buffer_points: Buffer to add/subtract from entry price when setting SL (in points, converted internally)
 */
void AdjustPosition::set_breakeven_sl_if_tp_crossed(string symbol, int runner_magic_no, double buffer_points) {
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);            // Current ask price (for sell comparisons)
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);            // Current bid price (for buy comparisons)
    int digits = (int) SymbolInfoInteger(symbol, SYMBOL_DIGITS);  // Symbol's decimal precision
    double buffer_price = buffer_points * _Point;                 // Convert buffer from points to price

    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);                                        // Get the position ticket
        if (!PositionSelectByTicket(ticket)) continue;                              // Select the position
        if (PositionGetString(POSITION_SYMBOL) != symbol) continue;                 // Only process positions for this symbol
        if ((int) PositionGetInteger(POSITION_MAGIC) != runner_magic_no) continue;  // Ensure it matches runner magic

        // --- Get position details ---
        long order_type = PositionGetInteger(POSITION_TYPE);    // POSITION_TYPE_BUY or POSITION_TYPE_SELL
        double entry = PositionGetDouble(POSITION_PRICE_OPEN);  // Entry price of the trade
        double sl = PositionGetDouble(POSITION_SL);             // Current stop loss
        double tp = PositionGetDouble(POSITION_TP);             // Should be 0 for runners
        string comment = PositionGetString(POSITION_COMMENT);   // Read comment to check for virtual TP

        // --- Parse virtual TP from comment ---
        // Format expected: "runner_tp:1.10500"
        double virtual_tp = 0.0;
        if (StringFind(comment, "runner_tp:") == 0) {
            string tp_str = StringSubstr(comment, StringLen("runner_tp:"));  // Extract number part
            virtual_tp = StringToDouble(tp_str);                             // Convert to double
        }

        // Skip if no virtual TP was found or invalid
        if (virtual_tp <= 0.0) continue;

        // Warn if a TP is still set (runner should not have one)
        if (tp > 0.0) {
            PrintFormat("Warning: Runner trade on %s (ticket %d) has a non-zero TP: %.5f (should be 0)", symbol, ticket, tp);
        }

        // --- Check if price has hit virtual TP ---
        bool tp_hit = false;
        if (order_type == POSITION_TYPE_BUY && bid >= virtual_tp)  // For buys, bid must be ≥ virtual TP
            tp_hit = true;
        if (order_type == POSITION_TYPE_SELL && ask <= virtual_tp)  // For sells, ask must be ≤ virtual TP
            tp_hit = true;
        if (!tp_hit) continue;

        // --- Set breakeven SL if TP was hit ---
        // Move SL to entry ± buffer. Leave TP unchanged (but should be 0.0 at init for runners)
        set_breakeven_sl_for_ticket(symbol, ticket, order_type, entry, sl, tp, digits, buffer_price, true);
    }
}

// ---------------------------------------------------------
void AdjustPosition::set_breakeven_sl_for_ticket(string symbol, ulong ticket, long order_type, double entry_price, double current_sl,
                                                 double current_tp, int digits, double buffer_price, bool remove_tp) {
    double breakeven_sl = (order_type == POSITION_TYPE_BUY) ? entry_price + buffer_price : entry_price - buffer_price;

    if ((order_type == POSITION_TYPE_BUY && current_sl >= breakeven_sl) || (order_type == POSITION_TYPE_SELL && current_sl <= breakeven_sl))
        return;

    MqlTradeRequest request = {};
    MqlTradeResult result;

    request.action = TRADE_ACTION_SLTP;
    request.symbol = symbol;
    request.position = ticket;
    request.sl = NormalizeDouble(breakeven_sl, digits);
    request.tp = remove_tp ? 0.0 : current_tp;
    request.magic = (int) PositionGetInteger(POSITION_MAGIC);

    if (!OrderSend(request, result)) {
        Print("Failed to adjust runner: ", symbol, ". Error: ", result.retcode);
    } else if (remove_tp) {
        Print("Runner upgraded to trailing: SL at breakeven, TP removed for ", symbol);
    }
}

// ---------------------------------------------------------

void AdjustPosition::set_fixed_sl(string symbol, int runner_magic_no, double fixed_sl_price) {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (!PositionSelectByTicket(ticket)) continue;
        if (PositionGetString(POSITION_SYMBOL) != symbol) continue;
        if ((int) PositionGetInteger(POSITION_MAGIC) != runner_magic_no) continue;

        double current_sl = PositionGetDouble(POSITION_SL);
        double current_tp = PositionGetDouble(POSITION_TP);

        if (current_sl == fixed_sl_price) continue;

        MqlTradeRequest request = {};
        MqlTradeResult result;

        request.action = TRADE_ACTION_SLTP;
        request.symbol = symbol;
        request.position = ticket;
        request.sl = fixed_sl_price;
        request.tp = current_tp;
        request.magic = runner_magic_no;

        if (!OrderSend(request, result)) {
            Print("Failed to set fixed SL for runner on ", symbol, ". Error: ", result.retcode);
        }
    }
}

// ---------------------------------------------------------

void AdjustPosition::set_trailing_sl(string symbol, int runner_magic_no, double sl_offset_points) {
    int digits = (int) SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double price = 0;
    double sl = 0;
    double offset = sl_offset_points * _Point;

    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (!PositionSelectByTicket(ticket)) continue;
        if (PositionGetString(POSITION_SYMBOL) != symbol) continue;
        if ((int) PositionGetInteger(POSITION_MAGIC) != runner_magic_no) continue;

        long type = PositionGetInteger(POSITION_TYPE);
        double current_sl = PositionGetDouble(POSITION_SL);
        double current_tp = PositionGetDouble(POSITION_TP);

        price = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);

        sl = (type == POSITION_TYPE_BUY) ? price - offset : price + offset;

        if ((type == POSITION_TYPE_BUY && sl <= current_sl) || (type == POSITION_TYPE_SELL && sl >= current_sl)) continue;

        MqlTradeRequest request = {};
        MqlTradeResult result;

        request.action = TRADE_ACTION_SLTP;
        request.symbol = symbol;
        request.position = ticket;
        request.sl = NormalizeDouble(sl, digits);
        request.tp = current_tp;
        request.magic = runner_magic_no;

        if (!OrderSend(request, result)) {
            Print("Failed to update trailing SL for runner on ", symbol, ". Error: ", result.retcode);
        }
    }
}
