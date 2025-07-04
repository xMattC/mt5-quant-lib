#include <Object.mqh>

class ChartUtils : public CObject {

public:
   void draw_line(double value, string name, color clr = clrBlack);
};

void ChartUtils::draw_line(double value, string name, color clr) {
   if (ObjectFind(0, name) < 0) {
      ResetLastError();

      if (!ObjectCreate(0, name, OBJ_HLINE, 0, 0, value)) {
         Print(__FUNCTION__, ": failed to create a horizontal line! Error code = ", GetLastError());
         return;
      }

      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   }

   ResetLastError();

   if (!ObjectMove(0, name, 0, 0, value)) {
      Print(__FUNCTION__, ": failed to move the horizontal line! Error code = ", GetLastError());
      return;
   }

   ChartRedraw();
}
