#property library

enum  LOT_MODE{
    LOT_MODE_FIXED,         // Fixed Lot Size
    LOT_MODE_PCT_ACCOUNT,   // Percent of Account (fixed)
    LOT_MODE_PCT_RISK       // Percent of Account at Risk (from SL)
};
enum  SL_MODE{
    SL_FIXED_PIPS,       // Fixed Pips    
    SL_FIXED_PERCENT,    // Fixed Percent
    SL_ATR_MULTIPLE,     // ATR Multiple
    SL_SPECIFIED_VALUE,  // Bespoke calculation in code
    NO_STOPLOSS,         // No Stop-loss
    SL_BREAKEVEN,        // Breakeven    
};
enum  TP_MODE{
    TP_FIXED_PIPS,       // Fixed Pips        
    TP_FIXED_PERCENT,    // Fixed Percent
    TP_ATR_MULTIPLE,     // ATR Multiple
    TP_SL_MULTIPLE,      // Multiple of Risk (from sl)
    TP_SPECIFIED_VALUE,  // Bespoke calculation in code    
    NO_TAKE_PROFIT,      // No Take-Profit 
};

enum  TIME_ZONES{
    NY,      // New York
    Lon,     // London
    Ffm,     // Frankfurt
    Syd,     // Sidney
    Mosc,    // Moscow
    Tok,     // Tokyo - no DST
};

enum  MULTI_SYM_MODE{
    MULTI_SYM_CHART,    // Chart Symbol only
    MULTI_SYM_FX_B5,    // FX Benchmark 5
    MULTI_SYM_FX_28     // FX 28 Majors
};

enum MODE_SPLIT_DATA{
    NO_SPLIT,   
    ODD_YEARS,  
    EVEN_YEARS,
    // ODD_MONTHS,
    // EVEN_MONTHS 
};