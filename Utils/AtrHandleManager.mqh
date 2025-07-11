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
    // Get or create an ATR handle for a specific symbol/timeframe/period
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

    // Get ATR value from buffer (returns EMPTY_VALUE if failure)
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

    // Release all handles in the cache
    void release_handles() {
        for (int i = 0; i < ArraySize(cache); i++) {
            if (cache[i].handle != INVALID_HANDLE)
                IndicatorRelease(cache[i].handle);
        }
        ArrayResize(cache, 0);
    }
};

