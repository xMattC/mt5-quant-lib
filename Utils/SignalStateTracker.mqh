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

    // Updates the signal for both long and short directions in one call, if the respective triggers are true.
    // curr_bar should refer to the last CLOSED bar (typically bar index 1).
    void update_signal(bool trig_long, bool trig_short, int curr_bar=1) {
        if (trig_long) last_signal_long = curr_bar;
        if (trig_short) last_signal_short = curr_bar;
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
