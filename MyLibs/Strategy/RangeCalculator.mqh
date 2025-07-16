//+------------------------------------------------------------------+
//|                                             RangeCalculator.mqh  |
//|            Determines a high/low price point within a time range |
//|                                                                  |
//|                                  2025 xMattC (github.com/xMattC) |
//+------------------------------------------------------------------+
#property copyright "2025 xMattC (github.com/xMattC)"
#property link      "https://github.com/xMattC"
#property version   "1.00"

#property library
#include <Trade/Trade.mqh>
#include <MyLibs/Utils/TimeZones.mqh>

class RangeCalculator : public CObject{

    protected:
        TimeZones tz;

        bool days_initlised;
        bool range_initlised;
        string symbol;
        ENUM_TIMEFRAMES calc_period;
        
        string inp_r_start_string;
        int r_duration;
        int r_expire;        
        int r_close;
        string inp_timezone;

        bool sun;
        bool mon;
        bool tue;
        bool wed;
        bool thu;
        bool fri;
        bool sat; 
        bool plot_range;
        datetime start_time;    // Start of the range
        datetime end_time;      // end of the range
        datetime order_expire_time;      // end of the range        
        datetime close_time;    // Close time
        double high;            // high of the range
        double low;             // low of the range
        double mid;             // mid of the range
        bool f_entry;           // flag if we are inside of the range
        bool f_high_breakout;   // flag if a high breakout occurred
        bool f_low_breakout;    // flag if a low breakout occurred    
        bool above_last;
        bool above_current;    
        bool below_last;
        bool below_current;     

        // private functions       
        void update_objects();    
        void draw_objects();
        void define_new_range();
        bool convert_input_time_strings(string t1, string t2, string t3, string t4);


    public:
        void calculate_range();
        double get_range_high();   
        double get_range_low();        
        double get_range_mid();   
        datetime get_range_start();        
        datetime get_range_end();    
        datetime get_order_expire_time();
        datetime get_range_close();                      
        bool get_range_high_breakout(); 
        bool get_range_low_breakout();  
        bool initilise_range(string inp_symbol, ENUM_TIMEFRAMES _calc_period, string t0, string t1, string t2, string t3, string time_zone, bool plot_range_inp);
        void range_days(bool _inp_sun, bool _inp_mon, bool _inp_tue, bool _inp_wed, bool _inp_thu, bool _inp_fri, bool _inp_sat);

};

// ---------------------------------------------------------------------
// Sets the allowed days for range calculation.
//
// Parameters:
// - _inp_sun : Allow Sunday.
// - _inp_mon : Allow Monday.
// - _inp_tue : Allow Tuesday.
// - _inp_wed : Allow Wednesday.
// - _inp_thu : Allow Thursday.
// - _inp_fri : Allow Friday.
// - _inp_sat : Allow Saturday.
// ---------------------------------------------------------------------
void RangeCalculator::range_days(bool _inp_sun, bool _inp_mon, bool _inp_tue, bool _inp_wed, bool _inp_thu, bool _inp_fri, bool _inp_sat){
    sun = _inp_sun;
    mon = _inp_mon;
    tue = _inp_tue;
    wed = _inp_wed;
    thu = _inp_thu;
    fri = _inp_fri;
    sat = _inp_sat; 
    days_initlised = true;
}

// ---------------------------------------------------------------------
// Initializes the range parameters.
//
// Parameters:
// - inp_symbol       : The symbol for the range.
// - _calc_period     : Timeframe for range calculation.
// - t1               : Start time string.
// - t2               : End time string.
// - t3               : Expiry time string.
// - t4               : Close time string.
// - time_zone        : Timezone name.
// - plot_range_inp   : Whether to plot the range.
//
// Returns:
// - true if initialization was successful; false otherwise.
// ---------------------------------------------------------------------
bool RangeCalculator::initilise_range(string inp_symbol, ENUM_TIMEFRAMES _calc_period, string t1, string t2, string t3, string t4, string time_zone, bool plot_range_inp){
    inp_r_start_string = t1;
    inp_timezone = time_zone;
    symbol = inp_symbol;
    calc_period =_calc_period;
    plot_range = plot_range_inp;
    start_time = 0; 
    end_time = 0;      
    close_time = 0;   
    high = 0;      
    low = DBL_MAX;    
    mid = 0;            
    f_entry = false;   
    f_high_breakout = false; 
    f_low_breakout = false; 
    above_last = false;
    above_current= false;    
    below_last= false;
    below_current= false;        
    if(!days_initlised){
        sun = true;
        mon = true;
        tue = true;
        wed = true;
        thu = true;
        fri = true;
        sat = true; 
    }
    range_initlised = true;

    bool corret_inputs = convert_input_time_strings(t1, t2, t3, t4);
    if(corret_inputs = false){
        return false;
    }
    return true;    
}

// ---------------------------------------------------------------------
// Converts time input strings to time deltas for range definition.
//
// Parameters:
// - t1 : Start time string.
// - t2 : End time string.
// - t3 : Expiry time string.
// - t4 : Close time string.
//
// Returns:
// - true if times were converted successfully; false on error.
// ---------------------------------------------------------------------
bool RangeCalculator::convert_input_time_strings(string t1, string t2, string t3, string t4){

    datetime _t1 = StringToTime(t1);
    datetime _t2 = StringToTime(t2);
    datetime _t3 = StringToTime(t3);
    datetime _t4 = StringToTime(t4);


    if(_t1 > _t2){ 
        _t2 = _t2 + PeriodSeconds(PERIOD_D1);
        _t3 = _t3 + PeriodSeconds(PERIOD_D1);
        _t4 = _t4 + PeriodSeconds(PERIOD_D1);                  
    }

    if(_t2 > _t3){ 
        _t3 = _t3 + PeriodSeconds(PERIOD_D1);
        _t4 = _t4 + PeriodSeconds(PERIOD_D1);                  
    }

    if(_t3 > _t4){ 
        _t4 = _t4 + PeriodSeconds(PERIOD_D1);
    }

    r_duration = (int)(_t2 - _t1);
    r_expire = (int)(_t3 - _t1);
    r_close = (int)(_t4 - _t1);

    if(_t4 - _t1 >= PeriodSeconds(PERIOD_D1)){
        Alert("INCORRECT RANGE INPUTS!");
        return false;
    }
    
    return true;
}

// ---------------------------------------------------------------------
// Returns the high value of the current range.
//
// Returns:
// - High price of the range.
// ---------------------------------------------------------------------
double RangeCalculator::get_range_high(){
        return high;
};

// ---------------------------------------------------------------------
// Returns the low value of the current range.
//
// Returns:
// - Low price of the range.
// ---------------------------------------------------------------------
double RangeCalculator::get_range_low(){
    return low;
};

// ---------------------------------------------------------------------
// Returns the mid value of the current range.
//
// Returns:
// - Mid price of the range.
// ---------------------------------------------------------------------
double RangeCalculator::get_range_mid(){
    return mid;
};

// ---------------------------------------------------------------------
// Returns the start time of the current range.
//
// Returns:
// - Range start time.
// ---------------------------------------------------------------------
datetime RangeCalculator::get_range_start(){
    return start_time;
};

// ---------------------------------------------------------------------
// Returns the end time of the current range.
//
// Returns:
// - Range end time.
// ---------------------------------------------------------------------
datetime RangeCalculator::get_range_end(){
    return end_time;
};


// ---------------------------------------------------------------------
// Returns the expiration time for range-based orders.
//
// Returns:
// - Order expiration time.
// ---------------------------------------------------------------------
datetime RangeCalculator::get_order_expire_time(){
    return order_expire_time;
};

// ---------------------------------------------------------------------
// Returns the close time of the current range.
//
// Returns:
// - Range close time.
// ---------------------------------------------------------------------
datetime RangeCalculator::get_range_close(){
    return close_time;
};

// ---------------------------------------------------------------------
// Returns the high breakout flag of the current range.
//
// Returns:
// - true if high breakout occurred; false otherwise.
// ---------------------------------------------------------------------
bool RangeCalculator::get_range_high_breakout(){
    return f_high_breakout;
};

// ---------------------------------------------------------------------
// Returns the low breakout flag of the current range.
//
// Returns:
// - true if low breakout occurred; false otherwise.
// ---------------------------------------------------------------------
bool RangeCalculator::get_range_low_breakout(){
    return f_low_breakout;
};    


void RangeCalculator::calculate_range(){

    f_high_breakout = false;
    f_low_breakout = false;

    double last_bar_high = iHigh(symbol, calc_period, 1); // shift 1 because 0 = live candle:
    double last_bar_low = iLow(symbol, calc_period, 1); // shift 1 because 0 = live candle:

    // range calculation 
    if(TimeCurrent() >= start_time && TimeCurrent() <= end_time){
        
        // set flag
        f_entry = true;

        // new high
        if(last_bar_high > high){
            high = last_bar_high;
            mid = (high + low)/2;       
            if(plot_range){
                update_objects();
            }
        }

        // new low
        if(last_bar_low < low){
            low = last_bar_low;
            mid = (high + low)/2;         
            if(plot_range){
                update_objects();
            }
        }
    }

    // calculate new reange if
    if( (TimeCurrent() >= close_time) // close time reached 
        || (end_time == 0) // range not calculated yet
        || (end_time !=0 && TimeCurrent() > end_time && !f_entry)  // there was a range calculated but no tick inside.
    ){
        define_new_range();
    }

    // check if we are after the range end
    if(TimeCurrent() >= end_time && end_time > 0 && f_entry){

        if(!f_high_breakout && last_bar_high >= high){
            above_last = above_current;
            above_current= true;    

            if(above_last==false && above_current == true){
                f_high_breakout = true;
            }
            else(f_high_breakout = false);
        }

        if(!f_low_breakout && last_bar_low >= low){
            below_last = below_current;
            below_current = true;    
            if(below_last == false && below_current == true){
                f_low_breakout = true;
            }       
            else(f_low_breakout = false);             
        }

    }
}

void RangeCalculator::define_new_range(){
    
    // reset range vars
    start_time = 0;
    end_time = 0;
    order_expire_time = 0;        
    close_time = 0;
    high = 0;
    low = INT_MAX;
    mid = 0;
    f_entry = false;

    // calculate range start time:
    datetime r_st = StringToTime(inp_r_start_string);
    start_time = tz.timezone_conversions(inp_timezone, r_st, "Broker");


    for(int i=0; i<8; i++){
        
        MqlDateTime tmp;
        TimeToStruct(start_time,tmp);
        int dow = tmp.day_of_week;
        
        if(TimeCurrent()>=start_time 
            || (dow==0 && !sun)
            || (dow==1 && !mon) 
            || (dow==2 && !tue)
            || (dow==3 && !wed)
            || (dow==4 && !thu)
            || (dow==5 && !fri)
            || (dow==6 && !sat)
            ){
                start_time += PeriodSeconds(PERIOD_D1);
        }
    }


    end_time = start_time + r_duration;
    order_expire_time = start_time + r_expire;
    close_time = start_time + r_close;

    if(plot_range){
        draw_objects();
    }
}

void RangeCalculator::update_objects(){

    string name = "Range Mid " + (string)start_time;
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,0, mid);
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,1, mid);
    // ObjectSetString(NULL, name , OBJPROP_TOOLTIP, "Range Mid");  

    name = "Order expire " + (string)order_expire_time;
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,0, high);
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,1, low);

    name = "Range start " + (string)start_time;
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,0, high);
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,1, low);  

    name = "Range end " + (string)end_time;
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,0, high);
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,1, low);

    datetime rct = r_close>=0 ? close_time : INT_MAX;  
    name = "Range close " + (string)rct;
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,0, high);
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,1, low); 

    name = "Range High " + (string)rct;
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,0, high);
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,1, high);   

    name = "Range Low " + (string)rct;
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,0, low);
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,1, low);   

    name = "range box "+ (string)start_time;
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,0, high);
    ObjectSetDouble(NULL, name, OBJPROP_PRICE,1, low);
    ObjectSetDouble(NULL, name +" ", OBJPROP_PRICE,0, high);
    ObjectSetDouble(NULL, name +" ", OBJPROP_PRICE,1, low);    

}

void RangeCalculator::draw_objects(){

    datetime rct = r_close>=0 ? close_time : INT_MAX;          

    // Range mid line
    string name = "Range Mid " + (string)start_time;;
    ObjectCreate(NULL, name, OBJ_TREND, 0, start_time, mid, rct, mid);
    ObjectSetString(NULL, name , OBJPROP_TOOLTIP, "Range Mid" + (string)mid);  
    ObjectSetInteger(NULL, name, OBJPROP_COLOR, clrGray);
    ObjectSetInteger(NULL, name, OBJPROP_WIDTH, 1);    
    ObjectSetInteger(NULL, name, OBJPROP_STYLE, STYLE_DOT);     

    // order lines 
    string name2 = "Order expire " + (string)order_expire_time;
    ObjectCreate(NULL, name2, OBJ_TREND, 0, order_expire_time, low, order_expire_time, high);
    ObjectSetString(NULL, name2, OBJPROP_TOOLTIP, "start of the range \n" + TimeToString(order_expire_time,TIME_DATE|TIME_MINUTES));
    ObjectSetInteger(NULL, name2, OBJPROP_COLOR, C'139,41,41');
    ObjectSetInteger(NULL, name2 ,OBJPROP_WIDTH, 2);    
    ObjectSetInteger(NULL, name2,OBJPROP_BACK, true);          

    name2 = "Range start " + (string)start_time;
    ObjectCreate(NULL, name2, OBJ_TREND, 0, start_time, low, start_time, high);
    ObjectSetInteger(NULL, name2, OBJPROP_COLOR, clrBlack);
    ObjectSetInteger(NULL, name2 ,OBJPROP_WIDTH, 2);    
    ObjectSetInteger(NULL, name2,OBJPROP_BACK, true);    

    name2 = "Range end " + (string)end_time;
    ObjectCreate(NULL, name2, OBJ_TREND, 0, end_time, low, end_time, high);
    ObjectSetInteger(NULL, name2, OBJPROP_COLOR, clrBlack);
    ObjectSetInteger(NULL, name2 ,OBJPROP_WIDTH, 2);    
    ObjectSetInteger(NULL, name2,OBJPROP_BACK, true);    

    name2 = "Range close " + (string)rct;
    ObjectCreate(NULL, name2, OBJ_TREND, 0, rct, low, rct, high);
    ObjectSetInteger(NULL, name2, OBJPROP_COLOR, clrBlack);
    ObjectSetInteger(NULL, name2 ,OBJPROP_WIDTH, 2);    
    ObjectSetInteger(NULL, name2,OBJPROP_BACK, true);    

    name2 = "Range High " + (string)rct;
    ObjectCreate(NULL, name2, OBJ_TREND, 0, start_time, high, rct, high);
    ObjectSetInteger(NULL, name2, OBJPROP_COLOR, clrBlack);
    ObjectSetInteger(NULL, name2 ,OBJPROP_WIDTH, 2);    
    ObjectSetInteger(NULL, name2,OBJPROP_BACK, true);    

    name2 = "Range Low " + (string)rct;
    ObjectCreate(NULL, name2, OBJ_TREND, 0, start_time, low, rct, low);
    ObjectSetInteger(NULL, name2, OBJPROP_COLOR, clrBlack);
    ObjectSetInteger(NULL, name2 ,OBJPROP_WIDTH, 2);    
    ObjectSetInteger(NULL, name2 ,OBJPROP_BACK, true);    

    // Box
    name = "range box " + (string)start_time;
    ObjectCreate(NULL, name, OBJ_RECTANGLE, 0, start_time, high, end_time, low);
    ObjectSetString(NULL,name,OBJPROP_TOOLTIP,"\n");
    ObjectSetInteger(NULL, name,OBJPROP_COLOR, C'128,177,173');
    ObjectSetInteger(NULL, name,OBJPROP_FILL, true);       
    ObjectSetInteger(NULL, name,OBJPROP_BACK, true);     

    ObjectCreate(NULL, name + " ", OBJ_RECTANGLE, 0, end_time, high, rct, low);
    ObjectSetString(NULL, name+ " ", OBJPROP_TOOLTIP, "\n");        
    ObjectSetInteger(NULL, name + " ",OBJPROP_FILL, true);        
    ObjectSetInteger(NULL, name + " ",OBJPROP_COLOR, C'165,220,215' );    
    ObjectSetInteger(NULL, name + " ",OBJPROP_BACK, true);   

    ChartRedraw();
}


