#property library
#include <Trade/Trade.mqh>
#include <MyLibs/TimeZones.mqh>
#include <MyLibs/Myfunctions.mqh>

enum EXIT_INDICATORS_LIST{
    AROON,
    ASO,    
};

class ExitIndicators : public CObject{
   
    protected:
        int handle;

    public:
        int  init_exit_indi_handle(EXIT_INDICATORS_LIST indi, string symbol, ENUM_TIMEFRAMES time_frame);
        bool  get_exit_indi_bool(EXIT_INDICATORS_LIST indi, int exit_handle, int data_type);

};

int ExitIndicators::init_exit_indi_handle(EXIT_INDICATORS_LIST indi, string symbol, ENUM_TIMEFRAMES time_frame){

    if(indi==AROON){
        handle=iCustom(symbol, time_frame, "MyIndicators\\AROON.ex5");

    }
    if(indi==ASO){
        handle=iCustom(symbol, time_frame, "MyIndicators\\ASO.ex5", 26, 9, 0, 3);

    }    
    return handle;
}

bool ExitIndicators::get_exit_indi_bool(EXIT_INDICATORS_LIST indi, int exit_handle, int data_type){

    bool long_exit;
    bool short_exit;

    if(indi==AROON){

        double indi_up[]; 
        ArraySetAsSeries(indi_up, true); 
        CopyBuffer(exit_handle,0,1,10,indi_up);

        double indi_down[]; 
        ArraySetAsSeries(indi_down, true); 
        CopyBuffer(exit_handle,1,1,10,indi_down);
        
        long_exit = (
            indi_up[0] < indi_down[0] 
            && indi_up[1] > indi_down[1]
        );

        short_exit = (
            indi_up[0] > indi_down[0]
            && indi_up[1] < indi_down[1]
        );
    }


    if(indi==ASO){

        double Bulls[];
        ArraySetAsSeries(Bulls, true);
        CopyBuffer(exit_handle,0,1,10,Bulls);

        double Bears[];
        ArraySetAsSeries(Bears, true);
        CopyBuffer(exit_handle,1,1,10,Bears);
        
        long_exit = (
            Bulls[0] < Bears[0]
            && Bulls[1] > Bears[1] 
        );

        short_exit = (
            Bulls[0] > Bears[0]
            && Bulls[1] < Bears[1]  
        );
    }


    if(data_type==1){return long_exit;}

    if(data_type==2){return short_exit;}    

    return false;

}
