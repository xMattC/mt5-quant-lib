class EntryState {
   public:
    int last_trigger_bar_long;
    int last_trigger_bar_short;
    int last_bl_cross_long;
    int last_bl_cross_short;
    int last_entry_long;
    int last_entry_short;

    // Constructor
    EntryState() {
        reset();
    }

    void reset() {
        last_trigger_bar_long = -1000;
        last_trigger_bar_short = -1000;
        last_bl_cross_long = -1000;
        last_bl_cross_short = -1000;
        last_entry_long = -1000;
        last_entry_short = -1000;
    }

    void update_trigger(bool trig_long, bool trig_short, int curr_bar) {
        if (trig_long) last_trigger_bar_long = curr_bar;
        if (trig_short) last_trigger_bar_short = curr_bar;
    }

    void update_baseline_cross(int curr_bar, double price, double baseline, double prev_price, double prev_baseline) {
        if (prev_price < prev_baseline && price > baseline) last_bl_cross_long = curr_bar;
        if (prev_price > prev_baseline && price < baseline) last_bl_cross_short = curr_bar;
    }

    void update_entry(bool is_long, int curr_bar) {
        if (is_long)
            last_entry_long = curr_bar;
        else
            last_entry_short = curr_bar;
    }
    int get_last_trigger(bool is_long) {
        return is_long ? last_trigger_bar_long : last_trigger_bar_short;
    }
    int get_last_cross(bool is_long) {
        return is_long ? last_bl_cross_long : last_bl_cross_short;
    }
    int get_last_entry(bool is_long) {
        return is_long ? last_entry_long : last_entry_short;
    }
};

// Snapshot of conditions for a potential entry signal
struct EntryContext {
    bool trigger;
    bool confirm;
    bool volume;
    bool recent;
    bool base_ok;
    bool near;
    bool far;
    int last_entry;
    int last_cross;
};

// Utility: check if signal occurred recently
bool is_recent(int signal_bar, int curr_bar, int lookback) {
    return (curr_bar - signal_bar) < lookback;
}

// Utility: build current entry condition context
EntryContext build_entry_context(bool is_long, double price, double baseline, double atr, int last_cross, int last_entry, bool trigger,
                                 bool confirm, bool volume, bool recent) {
    EntryContext ctx;
    ctx.trigger = trigger;
    ctx.confirm = confirm;
    ctx.volume = volume;
    ctx.recent = recent;
    ctx.base_ok = is_long ? (price > baseline) : (price < baseline);
    ctx.near = MathAbs(price - baseline) <= atr;
    ctx.far = MathAbs(price - baseline) > atr;
    ctx.last_entry = last_entry;
    ctx.last_cross = last_cross;
    return ctx;
}

// Class wrapper for entry logic
class EntryLogic {
   public:
    bool is_standard_entry(const EntryContext& ctx) {
        return ctx.trigger && ctx.confirm && ctx.volume && ctx.recent && ctx.base_ok && ctx.near;
    }

    bool is_pullback_entry(const EntryContext& ctx, int curr_bar) {
        return (curr_bar - ctx.last_cross <= 2) && ctx.confirm && ctx.volume && ctx.base_ok && ctx.far;
    }

    bool is_baseline_cross_entry(const EntryContext& ctx, double prev_price, double prev_baseline, double price, double baseline,
                                 bool is_long) {
        bool crossed = is_long ? (prev_price < prev_baseline && price > baseline) : (prev_price > prev_baseline && price < baseline);
        return crossed && ctx.confirm && ctx.volume && ctx.near;
    }

    bool is_continuation_entry(const EntryContext& ctx, int curr_bar, int look_back) {
        return (curr_bar - ctx.last_entry <= look_back) && ctx.last_entry > ctx.last_cross && ctx.trigger && ctx.confirm && ctx.base_ok;
    }
};
