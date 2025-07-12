#include <Object.mqh>

class ChartUtils : public CObject {
   public:
    void draw_line(double value, string name, color clr = clrBlack);
};

// ---------------------------------------------------------------------
// Draws or updates a horizontal line on the chart at the given price level.
//
// Parameters:
// - value : Price level at which to draw the line.
// - name  : Unique name for the line object.
// - clr   : Line color (default is black).
//
// Logic:
// - If the object doesn't exist, it creates a new horizontal line.
// - If the object exists, it moves it to the new price level.
// - Calls ChartRedraw to update the chart visually.
// ---------------------------------------------------------------------
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
