class SignalStateTracker {
private:

    // ---------------------------------------------------------------------
    // Index of the last long signal detected (default -1000 when unset).
    // ---------------------------------------------------------------------
    int last_signal_long;

    // ---------------------------------------------------------------------
    // Index of the last short signal detected (default -1000 when unset).
    // ---------------------------------------------------------------------
    int last_signal_short;

public:

    // ---------------------------------------------------------------------
    // Constructor initializes the signal tracker to a reset state.
    //
    // Logic:
    // - Sets both long and short signal indices to -1000.
    // ---------------------------------------------------------------------
    SignalStateTracker() {
        reset();
    }

    // ---------------------------------------------------------------------
    // Resets the signal tracker.
    //
    // Logic:
    // - Sets `last_signal_long` and `last_signal_short` to -1000,
    //   representing no signal recorded.
    // ---------------------------------------------------------------------
    void reset() {
        last_signal_long = -1000;
        last_signal_short = -1000;
    }

    // ---------------------------------------------------------------------
    // Updates internal state based on whether long/short signals occurred.
    //
    // Parameters:
    // - signal_long  : True if a long signal occurred this bar.
    // - signal_short : True if a short signal occurred this bar.
    //
    // Logic:
    // - If a signal is detected, sets the index to 1 (bar 1).
    // - Otherwise, increments the previous value if it was positive.
    // ---------------------------------------------------------------------
    void update_signal_tracker(bool signal_long, bool signal_short) {
        if (signal_long) {
            last_signal_long = 1;
        } else if (last_signal_long > 0) {
            last_signal_long++;
        }

        if (signal_short) {
            last_signal_short = 1;
        } else if (last_signal_short > 0) {
            last_signal_short++;
        }
    }

    // ---------------------------------------------------------------------
    // Checks if a long signal occurred within the last N bars.
    //
    // Parameters:
    // - max_bars : Number of bars to look back for the signal.
    //
    // Returns:
    // - True if a long signal occurred within `max_bars` bars.
    // ---------------------------------------------------------------------
    bool long_signal_recent(int max_bars) const {
        return has_long_signal() && (1 - last_signal_long <= max_bars);
    }

    // ---------------------------------------------------------------------
    // Checks if a short signal occurred within the last N bars.
    //
    // Parameters:
    // - max_bars : Number of bars to look back for the signal.
    //
    // Returns:
    // - True if a short signal occurred within `max_bars` bars.
    // ---------------------------------------------------------------------
    bool short_signal_recent(int max_bars) const {
        return has_short_signal() && (1 - last_signal_short <= max_bars);
    }

    // ---------------------------------------------------------------------
    // Indicates if any long signal has ever been recorded.
    //
    // Returns:
    // - True if a long signal index is not equal to -1000.
    // ---------------------------------------------------------------------
    bool has_long_signal() const {
        return last_signal_long != -1000;
    }

    // ---------------------------------------------------------------------
    // Indicates if any short signal has ever been recorded.
    //
    // Returns:
    // - True if a short signal index is not equal to -1000.
    // ---------------------------------------------------------------------
    bool has_short_signal() const {
        return last_signal_short != -1000;
    }

    // ---------------------------------------------------------------------
    // Returns the last bar index at which a long signal occurred.
    //
    // Returns:
    // - Integer index representing bars since long signal.
    // ---------------------------------------------------------------------
    int get_long_signal() const {
        return last_signal_long;
    }

    // ---------------------------------------------------------------------
    // Returns the last bar index at which a short signal occurred.
    //
    // Returns:
    // - Integer index representing bars since short signal.
    // ---------------------------------------------------------------------
    int get_short_signal() const {
        return last_signal_short;
    }
};
