#include <MyLibs/Utils/SignalStateTracker.mqh>

// This class manages a collection of SignalStateTracker instances — one per symbol.
// It allows you to track signals separately for each symbol in a multi-symbol EA.
class MultiSymbolSignalTracker {
   private:
    // Struct to hold one (symbol → tracker) mapping
    struct SymbolTracker {
        string symbol;                // Symbol name (e.g. "EURUSD", "HSI")
        SignalStateTracker* tracker;  // Pointer to the signal tracker for that symbol
    };

    SymbolTracker trackers[];  // Dynamic array of symbol-tracker pairs

    // Helper function: Find the index of the given symbol in the array
    int find_index(const string& symbol) {
        for (int i = 0; i < ArraySize(trackers); i++) {
            if (trackers[i].symbol == symbol) return i;  // Found symbol, return its index
        }
        return -1;  // Not found
    }

   public:
    // Destructor: automatically called when this object is destroyed (e.g. at EA shutdown)
    ~MultiSymbolSignalTracker() {
        clear();  // Clean up memory when done
    }

    // Returns the SignalStateTracker for the given symbol.
    // If it doesn't exist yet, it creates one and stores it.
    SignalStateTracker* get_tracker(const string& symbol) {
        int idx = find_index(symbol);
        if (idx != -1) return trackers[idx].tracker;  // Tracker already exists — return it

        // If not found, create a new tracker for this symbol
        SignalStateTracker* tracker = new SignalStateTracker();

        SymbolTracker item;
        item.symbol = symbol;
        item.tracker = tracker;

        // Add new item to dynamic array
        ArrayResize(trackers, ArraySize(trackers) + 1);
        trackers[ArraySize(trackers) - 1] = item;

        return tracker;
    }

    // Deletes all trackers and resets the array.
    // Should be called in OnDeinit() to free memory.
    void clear() {
        for (int i = 0; i < ArraySize(trackers); i++) {
            delete trackers[i].tracker;  // Manually free each dynamically created tracker
        }
        ArrayResize(trackers, 0);  // Reset array to empty
    }
};


/* ---------------------------------------------------------------------------
Example usage in an EA:
---------------------------------------------------------------------------

// Declare the tracker globally (outside OnTick/OnTimer)
MultiSymbolSignalTracker track_trigger;

// Inside your strategy() or OnTick():
void strategy(string symbol, ...) {
    bool trig_long = ...;  // Your signal logic
    bool trig_short = ...;

    // Update the signal tracker for this symbol
    track_trigger.get_tracker(symbol).update_signal(trig_long, trig_short);

    // Example: Check if a recent long signal occurred
    if (track_trigger.get_tracker(symbol).long_signal_recent(5)) {
        // Do something like open a trade
    }
}

// In OnDeinit():
void OnDeinit(const int reason) {
    track_trigger.clear();  // Clean up memory
}

*/