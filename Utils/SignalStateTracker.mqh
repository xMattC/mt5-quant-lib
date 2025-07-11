class SignalStateTracker {
   private:
    int last_signal_long;
    int last_signal_short;

   public:
    // Constructor initializes both directions to a default "unset" state.
    SignalStateTracker() {
        reset();
    }

    // Resets the tracked signal bar indexes to an invalid default value (-1000).
    void reset() {
        last_signal_long = -1000;
        last_signal_short = -1000;
    }

    // Updates the signal tracker based on trigger presence per bar.
    // If signal is detected, sets to 1. If not, increments previous value.
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

    // Returns true if a long signal occurred within the last `max_bars` bars.
    bool long_signal_recent(int max_bars) const {
        // Assumes current bar is always bar index 1 (last closed bar).
        return has_long_signal() && (1 - last_signal_long <= max_bars);
    }

    // Returns true if a short signal occurred within the last `max_bars` bars.
    bool short_signal_recent(int max_bars) const {
        // Assumes current bar is always bar index 1 (last closed bar).
        return has_short_signal() && (1 - last_signal_short <= max_bars);
    }

    // Returns true if a signal has been recorded for the long direction.
    bool has_long_signal() const {
        return last_signal_long != -1000;
    }

    // Returns true if a signal has been recorded for the short direction.
    bool has_short_signal() const {
        return last_signal_short != -1000;
    }

    // Returns the last recorded signal bar index for the long direction.
    int get_long_signal() const {
        return last_signal_long;
    }

    // Returns the last recorded signal bar index for the short direction.
    int get_short_signal() const {
        return last_signal_short;
    }
};
