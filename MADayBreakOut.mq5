#include <Trade/Trade.mqh>

input double Lotsize = 0.1;
input int Magic = 12345; 
input int TimeCloseHour = 23;
input int TimeCloseMin = 0; 

input ENUM_TIMEFRAMES Timeframe = PERIOD_D1;
input int LongMa = 100;
input int ShortMa = 50;
input ENUM_MA_METHOD MaMethod = MODE_SMA;
input ENUM_APPLIED_PRICE MaAppPrice = PRICE_CLOSE;
bool isPosOpen;

CTrade trade;

int handleMa;


int OnInit(){
   trade.SetExpertMagicNumber(Magic);
   
   handleMa = iMA(_Symbol, Timeframe, LongMa,0, MaMethod, MaAppPrice);

  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{


}

void OnTick(){

   double ma[];
   CopyBuffer(handleMa, MAIN_LINE, 1, 1, ma);
   
   double close1 = iClose(_Symbol, Timeframe, 1);
   double high1 = iHigh(_Symbol, Timeframe, 1);
   double low1 = iLow(_Symbol, Timeframe, 1);
   
   double close0 = iClose(_Symbol, Timeframe, 0);
   
   MqlDateTime dt;
   TimeCurrent(dt);
   
   dt.hour = TimeCloseHour;
   dt.min = TimeCloseMin;
   dt.sec = 0;
   
   datetime timeClose = StructToTime(dt);
   
   
   for(int i = PositionsTotal() -1; i>=0; i--){
      CPositionInfo pos;
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == Magic){
         isPosOpen = true ;
         if(TimeCurrent() >=  timeClose){
            if(trade.PositionClose(pos.Ticket())){
               Print(__FUNCTION__," > pos #", pos.Ticket()," was closed at closing time...");
            }
         }
      } 
   }
   
   if (isPosOpen && TimeCurrent() > timeClose){
      isPosOpen = false;
   }
  
   if(!isPosOpen && TimeCurrent() < timeClose){
      if(close1 > ma[0]){
         if(close0 > high1){
            // Execute buy order
            trade.Buy(Lotsize);
            isPosOpen = true;
            Print(__FUNCTION__," > Condition matched, buy order sent");
         }
      }
      else if(close1 < ma[0]){
         if(close0 < low1){
            // Execute sell order
            trade.Sell(Lotsize);
            isPosOpen = true;
            Print(__FUNCTION__," > Condition matched, sell order sent");
         }
      }
   }
   
}

   
