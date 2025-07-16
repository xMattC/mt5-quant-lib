//+------------------------------------------------------------------+
//|                                           AtrHandleManager.mqh   |
//|                        ATR Handle Caching Utility for MQL5 EAs   |
//|                                                                  |
//|                                  2025 xMattC (github.com/xMattC) |
//+------------------------------------------------------------------+
#property copyright "2025 xMattC (github.com/xMattC)"
#property link      "https://github.com/xMattC"
#property version   "1.00"

#include <Trade/SymbolInfo.mqh>

class AtrHandleManager {
private:
    struct AtrEntry {
        string symbol;
        ENUM_TIMEFRAMES tf;
        int period;
        int handle;
    };

    AtrEntry cache[];  // internal cache of ATR handles

public:

    // ---------------------------------------------------------------------
    // Returns a valid ATR handle for the given symbol, timeframe, and period.
    // Creates and caches the handle if not already available.
    //
    // Parameters:
    // - symbol : Trading symbol (e.g., "EURUSD").
    // - tf     : Timeframe (e.g., PERIOD_H1).
    // - period : ATR period (e.g., 14).
    //
    // Returns:
    // - The ATR indicator handle, or INVALID_HANDLE if failed.
    // ---------------------------------------------------------------------
    int get_atr_handle(string symbol, ENUM_TIMEFRAMES tf, int period) {
        for (int i = 0; i < ArraySize(cache); i++) {
            if (cache[i].symbol == symbol && cache[i].tf == tf && cache[i].period == period)
                return cache[i].handle;
        }

        int handle = iATR(symbol, tf, period);
        if (handle == INVALID_HANDLE) {
            Print("Failed to create ATR handle for ", symbol);
            return INVALID_HANDLE;
        }

        AtrEntry entry = { symbol, tf, period, handle };
        ArrayResize(cache, ArraySize(cache) + 1);
        cache[ArraySize(cache) - 1] = entry;

        return handle;
    }

    // ---------------------------------------------------------------------
    // Gets the ATR value for a given symbol, timeframe, and period.
    //
    // Parameters:
    // - symbol : Trading symbol (e.g., "EURUSD").
    // - tf     : Timeframe to use (e.g., PERIOD_H1).
    // - period : ATR period to calculate.
    // - shift  : Bar shift to read the value from (default is 1 for last closed bar. NEVER use 0!).
    //
    // Returns:
    // - ATR value at the given shift, or EMPTY_VALUE on failure.
    // ---------------------------------------------------------------------
    double get_atr_value(string symbol, ENUM_TIMEFRAMES tf, int period, int shift = 1) {
        int handle = get_atr_handle(symbol, tf, period);
        if (handle == INVALID_HANDLE) {
            PrintFormat("Invalid ATR handle for %s (TF=%d, Period=%d)", symbol, tf, period);
            return EMPTY_VALUE;
        }

        double buffer[];
        ArraySetAsSeries(buffer, true);

        if (CopyBuffer(handle, 0, shift, 1, buffer) != 1 || buffer[0] == EMPTY_VALUE) {
            PrintFormat("Failed to read ATR buffer for %s shift=%d", symbol, shift);
            return EMPTY_VALUE;
        }

        return buffer[0];
    }

    // ---------------------------------------------------------------------
    // Releases all cached ATR handles and clears the internal cache.
    //
    // Logic:
    // - Calls IndicatorRelease for each handle.
    // - Clears the `cache` array.
    // ---------------------------------------------------------------------
    void release_handles() {
        for (int i = 0; i < ArraySize(cache); i++) {
            if (cache[i].handle != INVALID_HANDLE)
                IndicatorRelease(cache[i].handle);
        }
        ArrayResize(cache, 0);
    }
};
