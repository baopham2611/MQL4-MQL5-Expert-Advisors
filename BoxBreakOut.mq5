#define OBJ_PREFIX_BOX "Box";

#include <Trade/Trade.mqh>

input double Lotsize = 0.1;
input double TpPercent = 0.5;
input double SlPercent = 0.5;
input ulong Magic = 123;


input int TriggerTimeMin = 360;
input int EndTimeMin = 1320;
input double RangePercent = 0.5;
input bool IsCloseAtEndTime = true;

double rangeHigh ;
double rangeLow ;

CTrade trade;

int OnInit(){
   trade.SetExpertMagicNumber(Magic);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   
  }

void OnTick(){
   MqlDateTime dt;
   TimeCurrent(dt);
   
   dt.hour = (int)(TriggerTimeMin / 60);
   dt.min = (int)(TriggerTimeMin % 60);
   dt.sec = 0; 
   datetime triggerTime = StructToTime(dt);
   
   
   dt.hour = (int)(EndTimeMin / 60);
   dt.min = (int)(EndTimeMin % 60);
   datetime endTime = StructToTime(dt);
   
   static int lastDay = 0;
   if(lastDay != dt.day_of_year){
      rangeHigh = 0;
      rangeLow = 0;
   

      datetime time0 = iTime(_Symbol, PERIOD_M1, 0);
      static datetime timestamp;
      if(timestamp != time0 && TimeCurrent() >= triggerTime){
         timestamp = time0;
         lastDay = dt.day_of_year;
      
         double open0 = iOpen(_Symbol, PERIOD_M1, 0);
         rangeHigh = open0 + open0 * RangePercent / 100 ;
         rangeLow  = open0 - open0 * RangePercent / 100 ;
         
         string objName = OBJ_PREFIX_BOX + ' ' + TimeToString(triggerTime);
         ObjectCreate(0,objName,OBJ_RECTANGLE,0,triggerTime,rangeHigh,endTime,rangeLow);
      }
   }
   
   if(IsCloseAtEndTime && TimeCurrent() >= endTime){
      for(int i = PositionsTotal()-1; i>=0; i--){
      CPositionInfo pos;
      if(pos.SelectByIndex(i) && pos.Symbol() ==  _Symbol && pos.Magic() == Magic){
         trade.PositionClose(pos.Ticket());
         }
      }
   }

   if(TimeCurrent() >= triggerTime && TimeCurrent() < endTime){
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      if(rangeHigh > 0 && bid > rangeHigh){
         double tp = 0;
         if(TpPercent > 0) tp = ask + ask * TpPercent / 100;
         double sl = ask - ask * SlPercent / 100;
         
         trade.Buy(Lotsize, _Symbol, ask, sl, tp, "Box Trading");
         rangeHigh = 0;
      }
      if(rangeLow > 0 && bid < rangeLow){
         double tp = 0;
         if(TpPercent > 0) tp = bid - bid * TpPercent / 100;
         double sl = bid + bid * SlPercent / 100;
         
         trade.Sell(Lotsize, _Symbol, ask, sl, tp, "Box Trading");
         rangeLow = 0;
      }
   }
 }

