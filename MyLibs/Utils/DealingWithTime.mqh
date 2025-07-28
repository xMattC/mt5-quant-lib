// ------------------------------------------------------------------
// This code was written by another developer (Calli).
// Basic testing confirms functionality, but I (xMattC) have not fully 
// reviewed or verified its correctness or quality.
// ------------------------------------------------------------------

//+------------------------------------------------------------------+
//|                                              DealingWithTime.mqh |
//|                                                            Calli |
//|                              https://www.mql5.com/de/users/gooly |
//+------------------------------------------------------------------+
#property copyright  "Calli"
#property link       "https://www.mql5.com/de/users/gooly"
#property version    "2.05"


//--- defines
#define TokyoShift   -32400                           // always 9h
#define NYShift      18000                            // winter 17h=22h GMT: NYTime + NYshift = GMT
#define LondonShift  0                                // winter London offset
#define SidneyShift  -36000                           // winter Sidney offset
#define FfmShift     -3600                            // winter Frankfurt offset
#define MoskwaShift  -10800                           // winter Moscow offset
#define FxOPEN       61200                            // = NY 17:00 = 17*3600
#define FxCLOSE      61200                            // = NY 17:00 = 17*3600
#define WeekInSec    604800                           // 60sec*60min*24h*7d = 604800 => 1 Week
#define FXOneWeek    432000                           // Su 22:00 - Fr 22:00 = 5*24*60*60 = 432000

#define  TOSTR(A) #A+": "+(string)(A)+"  "            // Print (TOSTR(hGMT)); => hGMT:22 (s.b.)  
string _WkDy[] =                                      // week days
   {
    "Su.",
    "Mo.",
    "Tu.",
    "We.",
    "Th.",
    "Fr.",
    "Sa.",
    "Su."
   };

#define  _t2s(t) TimeToString(t,TIME_DATE|TIME_SECONDS)  // shorten the code
#define  DoWi(t) ((int)((((t)-259200)%604800)/86400))    // (int)Day of Week Su=0,Mo=1,...
#define  DoWe(t) ENUM_DAY_OF_WEEK(((t)-D'1970.01.04')/86400 %7)  // SUNDAY, MONDAY,, ...
#define  DoWs(t) (_WkDy[DoWi(t)])                        // Day of Week as: Su., Mo., Tu., ....
#define  SoD(t) ((int)((t)%86400))                       // Seconds of Day
#define  SoW(t) ((int)(((t)-259200)%604800))             // Seconds of Week
#define  MoH(t) (int(((t)%3600)/60))                     // Minute of Hour 
#define  MoD(t) ((int)(((t)%86400)/60))                  // Minute of Day 00:00=(int)0 .. 23:59=1439
#define  ToD(t) ((t)%86400)                              // Time of Day in Sec (datetime) 86400=24*60*60
#define  HoW(t) (DoWi(t)*24+HoD(t))                      // Hour of Week 0..7*24 = 0..168 0..5*24 = 0..120
#define  HoD(t) ((int)(((t)%86400)/3600))                // Hour of Day 2018.02.03 17:55:56 => (int) 17
#define  rndHoD(t) ((int)((((t)%86400)+1800)/3600))%24   // rounded Hour of Day 2018.02.03 17:55:56 => (int) 18
#define  rndHoT(t) (((t)+1800)-(((t)+1800)%3600))        // rounded Hour of Time 2018.02.03 17:55:56 => (datetime) 2018.02.03 18:00:00
#define  BoD(t) ((t)-((t)%86400))                        // Begin of day 17.5 12:54 => 17.5. 00:00:00
#define  BoW(t) ((t)-((t)+345600)%604800)                // Begin of Week 2017.08.03 11:30 => Sun, 2017.07.30 00:00 (fixed version)
#define  Prev(day,t) ((t)-((t)+(4-(day))*86400)%604800)  // Previous Weekday for a specific time. Prev(SUNDAY, D'2017.08.03 11:30') => Sun, 2017.07.30 00:00

MqlDateTime tΤ; // hidden auxiliary variable: the Τ is a Greek charackt, so virtually no danger
int DoY(const datetime t) {TimeToStruct(t,tΤ); return(tΤ.day_of_year); } // TimeDayOfYear:    1..365(366) 366/3=122*24=2928 366/4=91.5*24=2196
int MoY(const datetime t) {TimeToStruct(t,tΤ); return(tΤ.mon); }        // TimeMonthOfYear:  1..12
int YoY(const datetime t) {TimeToStruct(t,tΤ); return(tΤ.year); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int DoM(const datetime t) {TimeToStruct(t,tΤ); return(tΤ.day); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int WoY(datetime t)   // Su=newWeek week of the year = nWeek(t) - nWeeks(1.1.) CalOneWeek   604800 // Su 22:00 - Su 22:00 = 7*24*60*60 = 604800
   {
    return(int((t-259200) / 604800) - int((t-172800 - DoY(t)*86400) / 604800) + 1); // calculation acc. to USA
   }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//--- global variables for time switches
int      DST_USD=0,                             // act time shift USD
         DST_EUR=0,                             // act time shift EU
         DST_AUD=0,                             // act time shift Australia
         DST_RUS=0;                             // D'2014.10.26 02:00', -10800,

datetime nxtSwitch_USD,                         // date of next switch
         nxtSwitch_EUR,                         // date of next switch
         nxtSwitch_AUD,                         // date of next switch
         nxtSwitch_RUB = D'2014.10.26 02:00';   // Russia s different :(



struct _OffsetBroker
   {
    int   USwinEUwin,                            // US=Winter & EU=Winter
          USsumEUsum,                            // US=Summer & EU=Summer
          USsumEUwin,                            // US=Summer & EU=Winter
          actOffset,                             // actual time offset of the broker
          actSecFX;                              // actual duration of FX in sec
    bool             set;                                   // are all set?
   };
_OffsetBroker OffsetBroker;



long RussiaTimeSwitch[][2] =
   {
    D'1970.01.00 00:00', -10800,
    D'1980.01.00 00:00', -10800,
    D'1981.04.01 00:00', -14400,
    D'1981.10.01 00:00', -10800,
    D'1982.04.01 00:00', -14400,
    D'1982.10.01 00:00', -10800,
    D'1983.04.01 00:00', -14400,
    D'1983.10.01 00:00', -10800,
    D'1984.04.01 00:00', -14400,
    D'1984.09.30 03:00', -10800,
    D'1985.03.31 02:00', -14400,
    D'1985.09.29 03:00', -10800,
    D'1986.03.30 02:00', -14400,
    D'1986.09.28 03:00', -10800,
    D'1987.03.29 02:00', -14400,
    D'1987.09.27 03:00', -10800,
    D'1988.03.27 02:00', -14400,
    D'1988.09.25 03:00', -10800,
    D'1989.03.26 02:00', -14400,
    D'1989.09.24 03:00', -10800,
    D'1990.03.25 02:00', -14400,
    D'1990.09.30 03:00', -10800,
    D'1991.03.31 02:00', -10800,
    D'1991.09.29 03:00',  -7200,
    D'1992.01.19 02:00', -10800,
    D'1992.03.29 02:00', -14400,
    D'1992.09.27 03:00', -10800,
    D'1993.03.28 02:00', -14400,
    D'1993.09.26 03:00', -10800,
    D'1994.03.27 02:00', -14400,
    D'1994.09.25 03:00', -10800,
    D'1995.03.26 02:00', -14400,
    D'1995.09.24 03:00', -10800,
    D'1996.03.31 02:00', -14400,
    D'1996.10.27 03:00', -10800,
    D'1997.03.30 02:00', -14400,
    D'1997.10.26 03:00', -10800,
    D'1998.03.29 02:00', -14400,
    D'1998.10.25 03:00', -10800,
    D'1999.03.28 02:00', -14400,
    D'1999.10.31 03:00', -10800,
    D'2000.03.26 02:00', -14400,
    D'2000.10.29 03:00', -10800,
    D'2001.03.25 02:00', -14400,
    D'2001.10.28 03:00', -10800,
    D'2002.03.31 02:00', -14400,
    D'2002.10.27 03:00', -10800,
    D'2003.03.30 02:00', -14400,
    D'2003.10.26 03:00', -10800,
    D'2004.03.28 02:00', -14400,
    D'2004.10.31 03:00', -10800,
    D'2005.03.27 02:00', -14400,
    D'2005.10.30 03:00', -10800,
    D'2006.03.26 02:00', -14400,
    D'2006.10.29 03:00', -10800,
    D'2007.03.25 02:00', -14400,
    D'2007.10.28 03:00', -10800,
    D'2008.03.30 02:00', -14400,
    D'2008.10.26 03:00', -10800,
    D'2009.03.29 02:00', -14400,
    D'2009.10.25 03:00', -10800,
    D'2010.03.28 02:00', -14400,
    D'2010.10.31 03:00', -10800,
    D'2011.03.27 02:00', -14400,
    D'2012.01.00 00:00', -14400,
    D'2014.10.26 02:00', -10800,
    D'3000.12.31 23:59', -10800
   };
int SzRussiaTimeSwitch = 67;                    // ArraySize of RussiaTimeSwitch

//+------------------------------------------------------------------+
//| Russian Time Switches                                            |
//+------------------------------------------------------------------+
void calcSwitchRUB(const datetime t)
   {
    int i = SzRussiaTimeSwitch; //ArrayRange(RussiaTimeSwitch,0); 66
    while(i-->0 && t < RussiaTimeSwitch[i][0])
        continue;
// t >= RussiaTimeSwitch[i][0]
    nxtSwitch_RUB  = (datetime)RussiaTimeSwitch[fmin(SzRussiaTimeSwitch-1,i+1)][0];
    DST_RUS        = (int)RussiaTimeSwitch[fmin(SzRussiaTimeSwitch-1,i+1)][1];
    return;
   }
//+------------------------------------------------------------------+

//--- Functions deling with time

//+------------------------------------------------------------------+
//| auxiliary function to get the seconds until FX is closed         |
//+------------------------------------------------------------------+
int SecTillClose(const datetime tC)
   {
    if(!OffsetBroker.set)
       {
        Print("OffsetBroker NOT set");
        return(0);
       }
    int s = SoW(tC);
// return the last second of the last bar of the FX-week
    if(s > OffsetBroker.actSecFX)
        return (OffsetBroker.actSecFX - s - 1);
// to be save in case negative values would appear for OffsetBroker.actSecFX
    else
        return (int(((tC + OffsetBroker.actSecFX) - s) - tC) - 1);
   }


//+------------------------------------------------------------------+
//| print out the time setting                                       |
//+------------------------------------------------------------------+
bool prtTimeSet(const datetime tC, const bool ok)
   {

    datetime arrTme[]; // tC is here not TimeCurrent() as in case of some weekend problems the time set up of the prev. week is used
    MqlRates rA[];
    datetime tB = BoW(tC);
    int b = CopyTime("EURUSD",PERIOD_H1,tB,1,arrTme),
        c = CopyRates("EURUSD",PERIOD_H1,arrTme[0],2,rA);
    int hNY, hGMT, hTC, hDiff;

    hNY   = HoD(arrTme[0] - SoD(arrTme[0]) + 16*3600);                        // get the hour of New York
    hGMT  = HoD(arrTme[0] - SoD(arrTme[0]) + 16*3600 + NYShift + DST_USD);    // get the hour of GMT

    hTC   = HoD(arrTme[0]);                                            // get the hour of the time given
    hDiff = hGMT - HoD(arrTme[0]);                                     // get the difference between GMT and the broker

    PrintFormat("\nOffset of %s: %i h = %i sec.\n%-30s %3s %s"+
                "\n%-30s %3s %s\n%-30s %3s %s\n%-30s %6i s  %.2f h"+
                "\n%-30s %s\n%-30s %3s %s\n%-30s %3s %s\n%-30s %3s %s",
                AccountInfoString(ACCOUNT_COMPANY),OffsetBroker.actOffset/3600,OffsetBroker.actOffset,
                "TimeCurrent:",               DoWs(tC),                  _t2s(tC),
                "First bar of this week:",    DoWs((BoW(tC))),         _t2s(BoW(tC)),
                "Last second of this week:",  DoWs(tC+SecTillClose(tC)),   _t2s(tC+SecTillClose(tC)),
                "Time left 'till weekend:",   SecTillClose(tC),            1.0*SecTillClose(tC)/3600.0,       // implicit casting to double
                "Time area:", (OffsetBroker.USwinEUwin>INT_MIN
                               ? "US=Winter & EU=Winter" : (OffsetBroker.USsumEUsum>INT_MIN
                                       ? "US=Summer & EU=Summer" : "US=Summer & EU=Winter")),
                "Next DST switch US:",        DoWs(nxtSwitch_USD),_t2s(nxtSwitch_USD),
                "Next DST switch EU:",        DoWs(nxtSwitch_EUR),_t2s(nxtSwitch_EUR),
                "Next DST switch AU:",        DoWs(nxtSwitch_AUD),_t2s(nxtSwitch_AUD)
               );
    return(ok);

   }
//+------------------------------------------------------------------+
//| function to determin time offset of the broker                   |
//+------------------------------------------------------------------+
bool setBokerOffset(const bool fromInit = true)
   {
    datetime arrTme[],                                          // array to copy time
             tC = TimeCurrent(),
             BegWk = BoW(tC),
             tDiff = tC - BegWk,
             FstBarWk=0,LstBarWk = 0;
    string txt4Fail = StringFormat("starting calc Time-Offest for %s at %s",AccountInfoString(ACCOUNT_COMPANY),_t2s(tC));

    int bb,b=0;
    OffsetBroker.USsumEUwin =
        OffsetBroker.USsumEUsum =
            OffsetBroker.USwinEUwin = INT_MIN;


//--- find the broker offset
    OffsetBroker.set = false;


    if(fromInit && tC-BegWk < 172800)     // 172800 = 48*3600 two days, if debugger/tester start on on Monday it might causes errors
       {
        bb = CopyTime("EURUSD",PERIOD_H1,BegWk-WeekInSec,1,arrTme);           // arrTme[0] last open time of broker before weekend
        bb = CopyTime("EURUSD",PERIOD_H1,arrTme[0],arrTme[0]+3600*52,arrTme); // gew the first bar after the weekend
        tC = arrTme[bb-1];
       }
    else
       {
        bb = CopyTime("EURUSD",PERIOD_H1,BegWk,1,arrTme);                     // arrTme[0] last open time of broker before weekend
        bb = CopyTime("EURUSD",PERIOD_H1,arrTme[0],arrTme[0]+3600*52,arrTme); // gew the first bar after the weekend
       }

//--- calc various dst for the (corrected?) tC
    if(nxtSwitch_USD < tC)
        calcSwitchUSD(tC);
    if(nxtSwitch_EUR < tC)
        calcSwitchEUR(tC);
    if(nxtSwitch_AUD < tC)
        calcSwitchAUD(tC);

    if(bb<0)
       {
        Print(txt4Fail," found: Switch USD: ",_t2s(nxtSwitch_USD)," Switch EUR: ",_t2s(nxtSwitch_EUR),"  Switch AUD: ",_t2s(nxtSwitch_AUD),
              "\n",__LINE__,": CopyTime() FAILED for EURUSD H1: need times from ",_t2s(BegWk+26*3600),", but there are only from ",
              _t2s((datetime)SymbolInfoInteger("EURUSD",SYMBOL_START_TIME))," error: ",_LastError);
        ResetLastError();
        return(prtTimeSet(tC, OffsetBroker.set));
       }

    while(++b<=bb-1)
       {
        if(arrTme[b]-arrTme[b-1]>7200)
           {
            FstBarWk = arrTme[b];
            LstBarWk = FstBarWk + FXOneWeek;
            break;
           }
       }

    if(LstBarWk == 0)
        return(prtTimeSet(tC, OffsetBroker.set));


    if(nxtSwitch_USD == 0)
        return(prtTimeSet(tC, OffsetBroker.set));

    if(DST_USD==0 && DST_EUR!=0)
       {
        Alert(__LINE__," ",TOSTR(DST_USD),TOSTR(DST_EUR),"  USwin && EUsum are still 0?");
        Print(txt4Fail," found(?): Switch USD: ",_t2s(nxtSwitch_USD)," Switch EUR: ",_t2s(nxtSwitch_EUR),"  Switch AUD: ",_t2s(nxtSwitch_AUD)," error: ",_LastError);
        return(prtTimeSet(tC, OffsetBroker.set));
       }
    if(nxtSwitch_AUD == 0)
        return(prtTimeSet(tC, OffsetBroker.set));


//------  get the broker offset:
    int hDiff, sClFX;
    datetime tGMT,tNY;

    tNY   = FstBarWk - SoW(FstBarWk) + 17*3600;
    tGMT  = FstBarWk - SoW(FstBarWk) + 17*3600 + NYShift + DST_USD;

    hDiff = (int)(tGMT/3600) - (int)(FstBarWk/3600); // time offset in hours, easier to read
    sClFX = SoW(FstBarWk + FXOneWeek);

    if(DST_USD+DST_EUR==0)                                      // both in winter (normal) time
       {
        OffsetBroker.actOffset = OffsetBroker.USwinEUwin = hDiff*3600;
        OffsetBroker.actSecFX  = sClFX; // last second of FX-week == Close at: tCl=SoW(TimeCurrent()) + OffsetBroker.actSecFX), time left: tCl - TimeCurrent()
        OffsetBroker.set       = true;
       }
    else
        if(DST_USD == DST_EUR)                                   // else both in summer time
           {
            OffsetBroker.actOffset = OffsetBroker.USsumEUsum = hDiff*3600;
            OffsetBroker.actSecFX  = sClFX; // last second of FX-week == Close at: tCl=SoW(TimeCurrent()) + OffsetBroker.actSecFX), time left: tCl - TimeCurrent()= SoW(tB);
            OffsetBroker.set       = true;
           }
        else
            if(DST_USD!=0 && DST_EUR==0)                          // US:summer EU:winter
               {
                OffsetBroker.actOffset = OffsetBroker.USsumEUwin = hDiff*3600;
                OffsetBroker.actSecFX  = sClFX; // lat second of FX-week == Close at: tCl=SoW(TimeCurrent()) + OffsetBroker.actSecFX), time left: tCl - TimeCurrent()= SoW(tB);
                OffsetBroker.set       = true;
               }

#ifdef _DEBUG
    if(!OffsetBroker.set)
       {
        Print(__FILE__,"[",__LINE__,"] Assigning the broker offset went wrong - somehow.");
        Print(txt4Fail," found: Switch USD: ",_t2s(nxtSwitch_USD)," Switch EUR: ",_t2s(nxtSwitch_EUR),"  Switch AUD: ",_t2s(nxtSwitch_AUD),
              "\n",__LINE__,": CopyTime() FAILED for EURUSD H1: need times from ",_t2s(BegWk+26*3600),", but there are only from ",
              _t2s((datetime)SymbolInfoInteger("EURUSD",SYMBOL_START_TIME))," error: ",_LastError);

       }
    else
        Print("Setting broker time offset at: ",DoWs(tC),", ",TimeToString(tC)," for ",AccountInfoString(ACCOUNT_COMPANY),
              "\nOffest (time+diff=GMT): ",TOSTR(OffsetBroker.actOffset)," sec => GMT: ",TimeToString(tC+OffsetBroker.actOffset),
              "  time area: ",(OffsetBroker.USwinEUwin>INT_MIN ? "US=Winter & EU=Winter" : (OffsetBroker.USsumEUsum>INT_MIN ? "US=Summer & EU=Summer" : "US=Summer & EU=Winter")),
              "\nget the seconds until FX closes (NY 17:00) with SecTillClose(TimeCurrent()): ",SecTillClose(tC)," sec or ",SecTillClose(tC)/3600," h, close time: ",DoWs((tC+SecTillClose(tC))),", ",TimeToString(tC+SecTillClose(tC))
             );
#else

    if(!OffsetBroker.set)
       {
        Print(__FILE__,"[",__LINE__,"] Assigning the broker offset went wrong - somehow.");
        Print(txt4Fail," found: Switch USD: ",_t2s(nxtSwitch_USD)," Switch EUR: ",_t2s(nxtSwitch_EUR),"  Switch AUD: ",_t2s(nxtSwitch_AUD),
              "\n",__LINE__,": CopyTime() FAILED for EURUSD H1: need times from ",_t2s(BegWk+26*3600),", but there are only from ",
              _t2s((datetime)SymbolInfoInteger("EURUSD",SYMBOL_START_TIME))," error: ",_LastError);
       }

#endif

    return(prtTimeSet(tC, OffsetBroker.set));
   }



//+------------------------------------------------------------------+
//| Time Switches of EU, US, ans AU                                  |
//| see: http://delphiforfun.org/programs/math_topics/dstcalc.htm    |
//+------------------------------------------------------------------+
/*+------------------------------------------------------------------+
//| calculation of DST for EUR                                       |
//| the weekend wasn't changed for EUR                               |
//+------------------------------------------------------------------*/
bool calcSwitchEUR(datetime now=0)
   {
    datetime spr=0,aut=0,tSw=0,t = now!=0 ? now : (nxtSwitch_AUD!=0 ? nxtSwitch_AUD : D'1972.10.29 0300') + 24*3600;
    int d, y = YoY(t), m=MoY(t);
    string stmp;

    d = (int)(31 - MathMod((4 + MathFloor(5*y/4)), 7));         // determing the last Sunday in March for the EU switch
    spr = StringToTime(""+(string)y+".03."+(string)d+" 03:00"); // convert to datetime format
    if(t < spr)
       {
        DST_EUR = 0;                                             // no time offset
        nxtSwitch_EUR = spr;                                     // set the next time switch
#ifdef _DEBUG   stmp = "EUR spr: last "+(string)(DoM(spr))+" Sunday  of March: "+(string)(MoY(spr)); #endif
#ifdef _DEBUG
        Print("DST_EUR for ",TimeToString(t)," DST: ",StringFormat("% 5i",DST_EUR),"  nxtSwitch: ",DoWs(nxtSwitch_EUR)," ",TimeToString(nxtSwitch_EUR),"  ",stmp);
#endif
        return(true);
       }
    d = (int)(31 - MathMod((1 + MathFloor(5*y/4)), 7));         // determing the last Sunday in October for the EU switch
    aut = StringToTime(""+(string)y+".10."+(string)d+" 03:00"); // convert to datetime format
#ifdef _DEBUG   stmp = "EUR aut: last "+(string)(DoM(aut))+" Sunday  of October: "+(string)(MoY(aut)); #endif

    if(t < aut)
       {
        DST_EUR =-3600;                           // = +1h => 09:00 London time = GMT+05h+DST_EU = GMT+0+1 = GMT+1;
        nxtSwitch_EUR = aut;                                     // set the next time switch
#ifdef _DEBUG
        Print("DST_EUR for ",TimeToString(t)," DST: ",StringFormat("% 5i",DST_EUR),"  nxtSwitch: ",DoWs(nxtSwitch_EUR)," ",TimeToString(nxtSwitch_EUR),"  ",stmp);
#endif
        return(true);
       }

// else next switch is next year;
    y++;
    t = StringToTime(""+(string)y+".01.01 03:00");
    if(calcSwitchEUR(t))
        return(true);                                           // re-calc the spring switch for the next year


    Alert(__FILE__,"[",__LINE__,"] ERROR for DST_EUR @ ",TimeToString(t)," DST: ",StringFormat("% 5i",DST_EUR),"  nxtSwitch: ",DoWs(nxtSwitch_EUR)," ",TimeToString(nxtSwitch_EUR),"  winter: ",TimeToString(aut),"  spring: ",TimeToString(spr));
    return(false);

   }
//+------------------------------------------------------------------+



/*+------------------------------------------------------------------+
//| calculation of DST for Sydney                                    |
   https://en.wikipedia.org/wiki/Daylight_saving_time_in_the_United_States
   In 1986 Congress enacted P.L. 99-359, amending the Uniform Time Act by changing the beginning of DST from last Sunday in April
   to the first Sunday in April and having the end remain the last Sunday in October.[10]
   These start and end dates were in effect from 1987 to 2006. The time was adjusted at 2:00 a.m. local time.

   By the Energy Policy Act of 2005, daylight saving time (DST) was extended in the United States beginning in 2007.[20]
   As from that year, DST begins on the second Sunday of March and ends on the first Sunday of November.[21]
   In years when April 1 falls on Monday through Wednesday, these changes result in a DST period that is five weeks longer;
   in all other years the DST period is instead four weeks longer.[22]

   In the U.S., daylight saving time starts on the second Sunday in March and ends on the first Sunday in November, with the time changes taking place at 2:00 a.m. local time.

   => ..1985 last Sunday in April      last Sunday in October.
      1986.. first Sunday in April     last Sunday in October.
      2005.. second Sunday of March    first Sunday of November.
//+------------------------------------------------------------------*/
bool calcSwitchUSD(datetime now=0)
   {
    datetime spr=0,aut=0,tSw=0,t = now!=0 ? now : (nxtSwitch_AUD!=0 ? nxtSwitch_AUD : D'1972.10.29 0300') + 24*3600;
    int d, y = YoY(t), m=MoY(t);
    string stmp;

    if(y<=1985)                                                         // last Sunday in April
       {
        d = (int)(30 - MathMod((6 + MathFloor(5*y/4)), 7));             // last Sunday in April
        spr = StringToTime(""+(string)y+".04."+(string)d+" 03:00");     // convert to datetime format
#ifdef _DEBUG   stmp = "USD spr: last "+(string)(DoM(spr))+" Sunday  of April: "+(string)(MoY(spr)); #endif

       }
    else
        if(y<2005)                                                      // first Sunday in April
           {
            d = (int)(7 - MathMod((4 + MathFloor(5*y/4)), 7));          // determing the first Sunday in April
            spr = StringToTime(""+(string)y+".04."+(string)d+" 03:00"); // convert to datetime format
#ifdef _DEBUG   stmp = "USD spr: first "+(string)(DoM(spr))+" Sunday  of April: "+(string)(MoY(spr)); #endif

           }
        else                                                            // second Sunday of March
           {
            d = (int)(14 - MathMod((1 + MathFloor(5*y/4)), 7));         // determing the second Sunday of March for the US switch
            spr = StringToTime(""+(string)y+".03."+(string)d+" 03:00"); // convert to datetime format
#ifdef _DEBUG   stmp = "USD spr: second "+(string)(DoM(spr))+" Sunday  of March: "+(string)(MoY(spr)); #endif

           }
    if(t < spr)
       {
        DST_USD = 0;                                                    // no time offset
        nxtSwitch_USD = spr;                                            // set the next time switch
#ifdef _DEBUG
        Print("USD-DST for ",TimeToString(t)," DST: ",StringFormat("% 5i",DST_USD),"  nxtSwitch: ",DoWs(nxtSwitch_USD)," ",TimeToString(nxtSwitch_USD),"  ",stmp);
#endif
        return(true);
       }

    if(y<2005)                                                          // last Sunday of October.
       {
        d = (int)(31 - MathMod((1 + MathFloor(5*y/4)), 7));             // determing the last Sunday of October for the EU switch
        aut = StringToTime(""+(string)y+".10."+(string)d+" 03:00");     // convert to datetime format
#ifdef _DEBUG   stmp = "USD aut: last "+(string)(DoM(aut))+" Sunday  of October: "+(string)(MoY(aut)); #endif

       }
    else
       {
        d = (int)(7 - MathMod((1 + MathFloor(5*y/4)), 7));              // determing the first Sunday of November for the US switch
        aut = StringToTime(""+(string)y+".11."+(string)d+" 03:00");     // convert to datetime format
#ifdef _DEBUG   stmp = "USD aut: first "+(string)(DoM(aut))+" Sunday  of November: "+(string)(MoY(aut)); #endif
       }

    if(t < aut)
       {
        DST_USD =-3600;                                                 // no time offset
        nxtSwitch_USD = aut;                                            // set the next time switch
#ifdef _DEBUG
        Print("USD-DST for ",TimeToString(t)," DST: ",StringFormat("% 5i",DST_USD),"  nxtSwitch: ",DoWs(nxtSwitch_USD)," ",TimeToString(nxtSwitch_USD),"  ",stmp);
#endif
        return(true);
       }

// else next switch is next year;
    y++;
    t = StringToTime(""+(string)y+".01.01 03:00");
    if(calcSwitchUSD(t))
        return(true);                                                   // re-calc the spring switch for the next year


    Alert(__FILE__,"[",__LINE__,"] ERROR for USD-DST @ ",TimeToString(t)," DST: ",StringFormat("% 5i",DST_USD),"  nxtSwitch: ",DoWs(nxtSwitch_USD)," ",TimeToString(nxtSwitch_USD),"  winter: ",TimeToString(aut),"  spring: ",TimeToString(spr));
    return(false);

   }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| calculation of DST for AUD                                       |
//+------------------------------------------------------------------+
bool calcSwitchAUD(datetime now=0)
   {
    datetime spr=0,aut=0,tSw=0,t = now!=0 ? now : (nxtSwitch_AUD!=0 ? nxtSwitch_AUD : D'1972.10.29 0300') + 24*3600;
    int d, y = YoY(t), m=MoY(t);
#ifdef _DEBUG    string stmp; #endif

    if(y<1986 || (y<=1995 && y>=1990))                                  // first Sunday of March
       {
        d = (int)(7 - MathMod((1 + MathFloor(5*y/4)), 7));              // first Sunday of March
        spr = StringToTime(""+(string)y+".03."+(string)d+" 03:00");     // convert to datetime format
#ifdef _DEBUG   stmp = "AUD spr: first "+(string)(DoM(spr))+" Sunday  of March: "+(string)(MoY(spr)); #endif

       }
    else
        if((y>=1986 && y<= 1989))     // 3rd Sunday March
           {
            d = (int)(21 - MathMod((1 + MathFloor(5*y/4)), 7));               // 3rd Sunday March
            spr = StringToTime(""+(string)y+".03."+(string)d+" 03:00");       // convert to datetime format
#ifdef _DEBUG   stmp = "AUD spr: 3rd "+(string)(DoM(spr))+" Sunday  of March: "+(string)(MoY(spr)); #endif

           }
        else
            if((y>=1996 && y<= 2005) || y==2007)     // last Sunday March
               {
                d = (int)(31 - MathMod((4 + MathFloor(5*y/4)), 7));           // determing the last Sunday of March for the EU switch
                spr = StringToTime(""+(string)y+".03."+(string)d+" 03:00");   // convert to datetime format
#ifdef _DEBUG   stmp = "AUD spr: last "+(string)(DoM(spr))+" Sunday  of March: "+(string)(MoY(spr)); #endif

               }
            else      // first Sunday April
               {
                d = (int)(7 - MathMod((4 + MathFloor(5*y/4)), 7));            // determing the first Sunday of April Australia switches time
                spr = StringToTime(""+(string)y+".04."+(string)d+" 03:00");   // convert to datetime format
#ifdef _DEBUG   stmp = "AUD spr: first "+(string)(DoM(spr))+" Sunday  of April: "+(string)(MoY(spr)); #endif
               }
    if(t < spr)
       {
        DST_AUD =-3600;                                                       // no time offset
        nxtSwitch_AUD = spr;                                                  // set the next time switch
#ifdef _DEBUG
        Print("AUD-DST for ",TimeToString(t)," DST: ",StringFormat("% 5i",DST_AUD),"  nxtSwitch: ",DoWs(nxtSwitch_AUD)," ",TimeToString(nxtSwitch_AUD),"  ",stmp);
#endif
        return(true);
       }

// else autm switch:
    if(y == 1986)    // last Sunday of Oct.
       {
        aut = StringToTime("1986.10.19 03:00");

       }
    else
        if(y < 2008)    // last Sunday of Oct.
           {
            d = (int)(31 - MathMod((1 + MathFloor(5*y/4)), 7));         // determing the last Sunday of October for the EU switch
            aut = StringToTime(""+(string)y+".10."+(string)d+" 03:00"); // convert to datetime format
#ifdef _DEBUG   stmp = "AUD aut: last "+(string)(DoM(aut))+" Sunday  of October: "+(string)(MoY(aut)); #endif

           }
        else     // first Sunday of Oct
           {
            d = (int)(7 - MathMod((5 + MathFloor(5*y/4)), 7));          // determing the first Sunday of Oct.  Australia switches time
            aut = StringToTime(""+(string)y+".10."+(string)d+" 03:00"); // convert to datetime format
#ifdef _DEBUG   stmp = "AUD aut: first "+(string)(DoM(aut))+" Sunday  of October: "+(string)(MoY(aut)); #endif
           }

    if(t < aut)
       {
        DST_AUD = 0;
        nxtSwitch_AUD = aut;                                            // set the next time switch
#ifdef _DEBUG
        Print("AUD-DST for ",TimeToString(t)," DST: ",StringFormat("% 5i",DST_AUD),"  nxtSwitch: ",DoWs(nxtSwitch_AUD)," ",TimeToString(nxtSwitch_AUD),"  ",stmp);
#endif
        return(true);
       }


// else next switch is next year;
    y++;
    t = StringToTime(""+(string)y+".01.01 03:00");
    if(calcSwitchAUD(t))
        return(true);                                                   // re-calc the spring switch for the next year

    Alert(__FILE__,"[",__LINE__,"] ERROR for AUD-DST @ ",TimeToString(t)," DST: ",StringFormat("% 5i",DST_AUD),"  nxtSwitch: ",DoWs(nxtSwitch_AUD)," ",TimeToString(nxtSwitch_AUD),"  winter: ",TimeToString(aut),"  spring: ",TimeToString(spr));
    return(false);

   }


//+------------------------------------------------------------------+
//| function to determin broker offset for the time given (tB)       |
//+------------------------------------------------------------------+
void checkTimeOffset(datetime tB)
   {
    if(tB < nxtSwitch_USD && tB < nxtSwitch_EUR && tB < nxtSwitch_AUD)
        return;                                                  // nothing has changed, return

    if(tB>nxtSwitch_USD)
        calcSwitchUSD(tB);                                      // US has switched
    if(tB>nxtSwitch_EUR)
        calcSwitchEUR(tB);                                      // EU has switched
    if(tB>nxtSwitch_AUD)
        calcSwitchAUD(tB);                                      // AU has switched
    if(tB>nxtSwitch_RUB)
        calcSwitchRUB(tB);                                      // RU has switched

    if(!setBokerOffset(false))                                       // recalculate the broker offset
        Alert(__FILE__,"[",__LINE__,"]  Assigning the broker offset went wrong - somehow.");


   }
//+------------------------------------------------------------------*/
