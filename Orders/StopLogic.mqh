class StopLogic {
public:
    double sl_specified_value_switch(string sl_mode, double inp_sl_var, double value);
    double tp_specified_value_switch(string tp_mode, double inp_tp_var, double value);
};

// ---------------------------------------------------------------------
// Selects stop loss value based on SL mode.
//
// Parameters:
// - sl_mode    : Stop loss mode ("SL_SPECIFIED_VALUE", etc).
// - inp_sl_var : User-input SL value (pips, percent, etc).
// - value      : Directly specified SL value.
//
// Returns:
// - `value` if SL mode is "SL_SPECIFIED_VALUE", otherwise `inp_sl_var`.
// ---------------------------------------------------------------------
double StopLogic::sl_specified_value_switch(string sl_mode, double inp_sl_var, double value) {
    if (sl_mode == "SL_SPECIFIED_VALUE") {
        return value;
    } else {
        return inp_sl_var;
    }
}

// ---------------------------------------------------------------------
// Selects take profit value based on TP mode.
//
// Parameters:
// - tp_mode    : Take profit mode ("TP_SPECIFIED_VALUE", etc).
// - inp_tp_var : User-input TP value (pips, percent, etc).
// - value      : Directly specified TP value.
//
// Returns:
// - `value` if TP mode is "TP_SPECIFIED_VALUE", otherwise `inp_tp_var`.
// ---------------------------------------------------------------------
double StopLogic::tp_specified_value_switch(string tp_mode, double inp_tp_var, double value) {
    if (tp_mode == "TP_SPECIFIED_VALUE") {
        return value;
    } else {
        return inp_tp_var;
    }
}
