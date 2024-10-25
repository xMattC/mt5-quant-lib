#property library
#include <Trade/Trade.mqh>
#include <MyLibs/TimeZones.mqh>

class TradingWindow : public CObject{

    protected:
        TimeZones tz;    
        bool in_window;
        datetime start_time; 
        datetime end_time; 

    public:  
        bool define_window(string t1, string t2, string time_zone, bool plot_range_inp=true);      
};


bool TradingWindow::define_window(string t1, string t2, string time_zone, bool plot_range=true){

    datetime _t1 = StringToTime(t1);
    datetime _t2 = StringToTime(t2);
    if(_t1 > _t2){ 
        _t2 = _t2 + PeriodSeconds(PERIOD_D1);               
    }
    int w_duration = (int)(_t2 - _t1);

    // window flag 
    if(TimeCurrent() >= start_time && TimeCurrent() <= end_time){
        in_window = true;    
    }

    // define new window
    if(TimeCurrent() >= end_time){

        in_window = false;   
        start_time = tz.timezone_conversions(time_zone, StringToTime(t1), "Broker");
            
        if(TimeCurrent()>=start_time){
            start_time += PeriodSeconds(PERIOD_D1);
        }

        end_time = start_time + w_duration;
        
        if(plot_range){
            
            string name = "Start Time" + (string)start_time;
            if(start_time>0){
                ObjectCreate(NULL, name, OBJ_VLINE, 0, start_time, 0);
                ObjectSetInteger(NULL, name,OBJPROP_COLOR, clrBlue);    
                ObjectSetInteger(NULL, name,OBJPROP_BACK, true);         
            }

            name = "End Time" + (string)end_time;
            if(end_time>0){
                ObjectCreate(NULL, name, OBJ_VLINE, 0, end_time, 0);
                ObjectSetInteger(NULL, name,OBJPROP_COLOR, C'56,108,26');
                ObjectSetInteger(NULL, name,OBJPROP_BACK, true);         
            }
            ChartRedraw();
        }
    }
    return in_window;    
}


