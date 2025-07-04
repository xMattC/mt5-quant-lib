class StopLogic {
   public:
      double sl_specified_value_switch(string sl_mode, double inp_sl_var, double value);
      double tp_specified_value_switch(string tp_mode, double inp_tp_var, double value);
};

double StopLogic::sl_specified_value_switch(string sl_mode, double inp_sl_var, double value) {
   if (sl_mode == "SL_SPECIFIED_VALUE") {
      return value;
   } else {
      return inp_sl_var;
   }
}

double StopLogic::tp_specified_value_switch(string tp_mode, double inp_tp_var, double value) {
   if (tp_mode == "SL_SPECIFIED_VALUE") {
      return value;
   } else {
      return inp_tp_var;
   }
}
