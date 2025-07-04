class SymbolUtils {

public:
   double adjusted_point(string symbol);
   double get_bid_ask_price(string symbol, int price_side);
};

/**
 * Adjusts the point size for symbols with 3 or 5 digits (e.g. JPY pairs or fractional pips).
 * Example: if symbol has 5 digits, 1 pip = 10 points.
 */
double SymbolUtils::adjusted_point(string symbol) {
   int symbol_digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   int digits_adjust = (symbol_digits == 3 || symbol_digits == 5) ? 10 : 1;

   double point_val = SymbolInfoDouble(symbol, SYMBOL_POINT);
   return point_val * digits_adjust;
}


/**
 * Returns either bid or ask price for a symbol, normalised to correct digits.
 *
 * param price_side: 1 for ASK, 2 for BID
 */
double SymbolUtils::get_bid_ask_price(string symbol, int price_side) {
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double ask = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_ASK), digits);
   double bid = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_BID), digits);

   if (price_side == 1) return ask;
   if (price_side == 2) return bid;

   return 0.0;  // fallback if invalid side passed
}
