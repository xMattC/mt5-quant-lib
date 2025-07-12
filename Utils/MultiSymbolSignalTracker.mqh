#include <MyLibs/Utils/SignalStateTracker.mqh>

// ---------------------------------------------------------------------
// This class manages a collection of SignalStateTracker instances — one per symbol.
// It allows you to track signals separately for each symbol in a multi-symbol EA.
// ---------------------------------------------------------------------
class MultiSymbolSignalTracker {
private:

    // ---------------------------------------------------------------------
    // Internal struct to associate a symbol with a SignalStateTracker.
    // ---------------------------------------------------------------------
    struct SymbolTracker {
        string symbol;
        SignalStateTracker* tracker;
    };

    SymbolTracker trackers[];  // Dynamic array of symbol-tracker mappings

    // ---------------------------------------------------------------------
    // Finds the index of the symbol in the tracker array.
    // ---------------------------------------------------------------------
    int find_index(const string& symbol) {
        for (int i = 0; i < ArraySize(trackers); i++) {
            if (trackers[i].symbol == symbol)
                return i;
        }
        return -1;
    }

public:

    // ---------------------------------------------------------------------
    // Destructor. Cleans up allocated memory when the object is destroyed.
    // ---------------------------------------------------------------------
    ~MultiSymbolSignalTracker() {
        clear();
    }

    // ---------------------------------------------------------------------
    // Retrieves the SignalStateTracker instance for a given symbol.
    // Creates and stores a new one if it doesn't exist yet.
    //
    // Parameters:
    // - symbol : Symbol for which to retrieve the signal tracker.
    //
    // Returns:
    // - Pointer to the SignalStateTracker instance.
    // ---------------------------------------------------------------------
    SignalStateTracker* get_tracker(const string& symbol) {
        int idx = find_index(symbol);
        if (idx != -1)
            return trackers[idx].tracker;

        // Create new tracker
        SignalStateTracker* tracker = new SignalStateTracker();

        SymbolTracker item;
        item.symbol = symbol;
        item.tracker = tracker;

        ArrayResize(trackers, ArraySize(trackers) + 1);
        trackers[ArraySize(trackers) - 1] = item;

        return tracker;
    }

    // ---------------------------------------------------------------------
    // Clears all SignalStateTracker instances and resets the internal array.
    // Should be called in `OnDeinit()` to avoid memory leaks.
    //
    // Logic:
    // - Deletes each dynamically allocated SignalStateTracker.
    // - Resets array size to 0.
    // ---------------------------------------------------------------------
    void clear() {
        for (int i = 0; i < ArraySize(trackers); i++) {
            delete trackers[i].tracker;
        }
        ArrayResize(trackers, 0);
    }
};
