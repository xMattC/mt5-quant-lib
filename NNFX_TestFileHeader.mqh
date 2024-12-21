#include <MyLibs/Myfunctions.mqh>
#include <MyLibs/OrderManagement.mqh>
#include <MyLibs/MyEnums.mqh>
#include <MyLibs/CustomMax.mqh>
CustomMax cm;
MyFunctions mf;
OrderManagment om;
//---  
string SymbolsArray[];
input LOT_MODE  inp_lot_mode    = LOT_MODE_PCT_RISK;    // Lot Size Mode
input double    inp_lot_var     = 2;                    // Lot Size Var
input SL_MODE   inp_sl_mode     = SL_ATR_MULTIPLE;      // Stop-loss Mode
input double    inp_sl_var      = 1.5;                    // Stop-loss Var 
input TP_MODE   inp_tp_mode     = TP_ATR_MULTIPLE;      // Take-profit Mode
input double    inp_tp_var      = 1;                  // Take-Profit Var
string lot_mode = EnumToString(inp_lot_mode);
string sl_mode  = EnumToString(inp_sl_mode);
string tp_mode  = EnumToString(inp_tp_mode);
input CUSTOM_MAX_TYPE inp_custom_criteria = CM_WIN_PERCENT_200T;
input MULTI_SYM_MODE inp_sym_mode = MULTI_SYM_FX_B5;
input MODE_SPLIT_DATA inp_data_split_method = NO_SPLIT;
input int inp_force_opt = 1;
input group "-----------------------------------------"





