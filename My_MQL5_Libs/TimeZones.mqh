//+------------------------------------------------------------------+
//|                                                    TimeZones.mqh |
//|                                                           xMattC |
//+------------------------------------------------------------------+
#property library
#include <Trade/Trade.mqh>
#include <MyLibs/DealingWithTime.mqh>

class TimeZones: public CObject{ 
   
    protected:
      string dt_s;
      int len;
      string dt_string;
      datetime tC, tGMT, tNY, tLon, tFfm, tMosc, tSyd, tTok;
      datetime tz_time;
      string tz_date;
      datetime time_start;
      datetime time_end;
      bool is_time;
      datetime tGIVEN;
      datetime tREQ;      
      datetime tzt;
      datetime tz_req;
      double ny_daily_close_protected(string symbol, int shift_days, bool print_data=false);       
      double required_close;

    public:
         string get_date_string_from_datetime(datetime dt);
         datetime get_timezone_time(string time_zone, bool print_time);
         datetime timezone_conversions(string time_zone_known, datetime time_given, string time_zone_required);
         double ny_daily_close(string symbol, int shift_days, bool print_data=false);       
};

string TimeZones::get_date_string_from_datetime(datetime dt){
   dt_s = TimeToString(dt);
   len = StringLen(dt_s);
   dt_string = StringSubstr(dt_s, 0, len-5);
   return dt_string;
}


datetime TimeZones::get_timezone_time(string time_zone, bool print_time){
   // https://www.mql5.com/en/code/45287
   // https://www.mql5.com/en/articles/9926
   // https://www.mql5.com/en/articles/9929

   checkTimeOffset(TimeCurrent()); // check changes of DST
   // cto();

   tC    = TimeCurrent();
   tGMT  = TimeCurrent() + OffsetBroker.actOffset;   // GMT
   tNY   = tGMT - (NYShift+DST_USD);                 // time in New York (EST)
   tLon  = tGMT - (LondonShift+DST_EUR);             // time in London
   tFfm  = tGMT - (FfmShift+DST_EUR);                // time in Frankfurt
   tSyd  = tGMT - (SidneyShift+DST_AUD);             // time in Sidney
   tMosc = tGMT - (MoskwaShift+DST_RUS);             // time in Moscow
   tTok  = tGMT - (TokyoShift);                      // time in Tokyo - no DST

   if(print_time==true){
      Print("----------------------------------");
      Print("Broker: ", tC);
      Print("GMT: ", tGMT);
      Print("time in New York: ", tNY);
      Print("time in London: ", tLon);
      Print("time in Frankfurt: ", tFfm);
      Print("time in Sidney: ", tSyd);
      Print("time in Moscow: ", tMosc);
      Print("time in Tokyo: ", tTok); 
   }

   if(time_zone=="NY"){return tNY;}
   if(time_zone=="Lon"){return tLon;}
   if(time_zone=="Ffm"){return tFfm;}
   if(time_zone=="Syd"){return tSyd;}
   if(time_zone=="Mosc"){return tMosc;}
   if(time_zone=="Tok"){return tTok;}

   return NULL;
}


datetime TimeZones::timezone_conversions(string time_zone_known, datetime time_given, string time_zone_required){
   // https://www.mql5.com/en/code/45287
   // https://www.mql5.com/en/articles/9926
   // https://www.mql5.com/en/articles/9929

   tGIVEN = time_given; //StringToTime(time_given);  
   
   checkTimeOffset(tGIVEN); // check changes of DST

   // Get GMT:
   if(time_zone_known=="GMT"     ){tGMT = tGIVEN;}
   if(time_zone_known=="Broker"  ){tGMT = tGIVEN + OffsetBroker.actOffset;}
   if(time_zone_known=="NY"      ){tGMT = tGIVEN + (NYShift+DST_USD);}
   if(time_zone_known=="Lon"     ){tGMT = tGIVEN + (LondonShift+DST_EUR);}
   if(time_zone_known=="Ffm"     ){tGMT = tGIVEN + (FfmShift+DST_EUR);}
   if(time_zone_known=="Syd"     ){tGMT = tGIVEN + (SidneyShift+DST_AUD);}   
   if(time_zone_known=="Mosc"    ){tGMT = tGIVEN + (MoskwaShift+DST_RUS);}  
   if(time_zone_known=="Tok"     ){tGMT = tGIVEN + (TokyoShift);}  

   // define the required time:
   tREQ = NULL;
   if(time_zone_required=="GMT"     ){tREQ = tGMT;}
   if(time_zone_required=="Broker"  ){tREQ = tGMT - OffsetBroker.actOffset;}
   if(time_zone_required=="NY"      ){tREQ = tGMT - (NYShift+DST_USD);}
   if(time_zone_required=="Lon"     ){tREQ = tGMT - (LondonShift+DST_EUR);}
   if(time_zone_required=="Ffm"     ){tREQ = tGMT - (FfmShift+DST_EUR);}
   if(time_zone_required=="Syd"     ){tREQ = tGMT - (SidneyShift+DST_AUD) ;}
   if(time_zone_required=="Mosc"    ){tREQ = tGMT - (MoskwaShift+DST_RUS);}
   if(time_zone_required=="Tok"     ){tREQ = tGMT - (TokyoShift);}      

   return tREQ;
}

// Calculte NY close time:
double TimeZones::ny_daily_close(string symbol, int shift_days, bool print_data=false){
   required_close = ny_daily_close_protected(symbol, shift_days, print_data);
   return required_close;
}
double TimeZones::ny_daily_close_protected(string symbol, int shift_days, bool print_data=false){

   // Get the brokers times for when NY openend today and tomorrow:   
   datetime time_5pm = iTime(symbol, PERIOD_D1 , 0) - (PeriodSeconds(PERIOD_H1) * 7);
   datetime ny_close_in_brokers_time = timezone_conversions("NY", time_5pm, "Broker");   
   datetime ny_close_time = ny_close_in_brokers_time + PeriodSeconds(PERIOD_D1);  // ny close tomorrow

   if(TimeCurrent()<ny_close_time){
      ny_close_time = ny_close_time - PeriodSeconds(PERIOD_D1); // ny close today
   }

   // Get the number of hours since NY closed:  
   int shift = iBarShift(symbol, PERIOD_H1, ny_close_time, false) + 1;  
   shift = shift + (24 * (shift_days - 1)); // shift days if required:  

   double ny_close = iClose(symbol,PERIOD_H1, shift);
   double br_close = iClose(symbol,PERIOD_H1, 1);

   if(print_data==true){
      Print("shift ",shift);  
      Print("time_5pm ",time_5pm);        
      Print("ny_close_in_brokers_time ",ny_close_in_brokers_time);                      
      Print("ny_close_time ",ny_close_time);                  
      Print("ny_close ", ny_close);
      Print("br_close ",br_close);
   }
   return ny_close;
}