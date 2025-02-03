#property version "1.00"
#include <Trade/Trade.mqh>

int Magic = 123;
double lotsize = 0.05;
double equity = 1000;

int handleTrendMAFast;
int handleTrendMASlow;

int handleMAFast;
int handleMAMid;
int handleMASlow;

CTrade trade;

int OnInit()
  {
   trade.SetExpertMagicNumber(Magic);
   
   handleTrendMAFast = iMA(_Symbol,PERIOD_H1,8,0,MODE_EMA,PRICE_CLOSE);
   handleTrendMASlow = iMA(_Symbol,PERIOD_H1,21,0,MODE_EMA,PRICE_CLOSE);
   
   
   handleMAFast = iMA(_Symbol,PERIOD_M5,8,0,MODE_EMA,PRICE_CLOSE);
   handleMAMid = iMA(_Symbol,PERIOD_M5,13,0,MODE_EMA,PRICE_CLOSE);
   handleMASlow = iMA(_Symbol,PERIOD_M5,21,0,MODE_EMA,PRICE_CLOSE);
      
   Print("SimpleAndProfitEA Started");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   Print("SimpleAndProfitEA Stopped");
  }
  
double dynamicLotSize() {
    double accountRisk = 0.02; // Risk 2% of account per trade
    int atr = iATR(_Symbol, PERIOD_H1, 14); // Average True Range for volatility
    double riskPerPoint = atr * 10; // Example: Adjust multiplier based on leverage and pip cost
    
    return NormalizeDouble((equity * accountRisk) / riskPerPoint, 2);
}

void OnTick()
  {
   lotsize = dynamicLotSize();
   double maTrendFast[], maTrendSlow[], maFast[], maMid[], maSlow[];
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   
   
   CopyBuffer(handleTrendMAFast,0,0,1,maTrendFast);
   CopyBuffer(handleTrendMASlow,0,0,1,maTrendSlow);

   
   CopyBuffer(handleMAFast,0,0,1,maFast);
   CopyBuffer(handleMAMid,0,0,1,maMid);
   CopyBuffer(handleMASlow,0,0,1,maSlow);
     
   
   int trendDirection = 0;
   if (maTrendFast[0] >= maTrendSlow[0] && bid > maTrendFast[0]){
      trendDirection = 1;
   }else if (maTrendFast[0] < maTrendSlow[0] && bid < maTrendFast[0]) {
      trendDirection = -1;
   } else{
      trendDirection = 0;
   }
   
   
   int positions = 0;
   for (int tradeIndex = PositionsTotal()-1; tradeIndex >= 0; tradeIndex--){
      ulong posTicket = PositionGetTicket(tradeIndex);
      if (PositionSelectByTicket(posTicket)){
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == Magic){
            positions += 1 ;
            
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
               if(PositionGetDouble(POSITION_VOLUME) >= lotsize){
                  double tp = PositionGetDouble(POSITION_PRICE_OPEN) + (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL));
                  
                  if(bid >= tp){
                     if(trade.PositionClosePartial(posTicket, NormalizeDouble(PositionGetDouble(POSITION_VOLUME)/2,2))){
                     
                        double sl = PositionGetDouble(POSITION_PRICE_OPEN);
                        sl = NormalizeDouble(sl,_Digits);
                        if(trade.PositionModify(posTicket,sl,0)){
                           
                        }
                     }
                  }
               }else{
                  int lowest = iLowest(_Symbol,PERIOD_M5, MODE_LOW, 3, 1);
                  double sl = iLow(_Symbol,PERIOD_M5,lowest);
                  sl = NormalizeDouble(sl,_Digits);
                  
                  if(sl > PositionGetDouble(POSITION_SL)){
                     if(trade.PositionModify(posTicket,sl,0)){
                        
                     }
                  }
               }
            }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
               if(PositionGetDouble(POSITION_VOLUME) >= lotsize){
                  double tp = PositionGetDouble(POSITION_PRICE_OPEN) - (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL));
               
                  if(bid <= tp){
                     if(trade.PositionClosePartial(posTicket, NormalizeDouble(PositionGetDouble(POSITION_VOLUME)/2,2))){
                     
                        double sl = PositionGetDouble(POSITION_PRICE_OPEN);
                        sl = NormalizeDouble(sl,_Digits);
                        if(trade.PositionModify(posTicket,sl,0)){
                        
                     }
                  }
               }
               }else{
                  int highest = iHighest(_Symbol,PERIOD_M5, MODE_HIGH, 3, 1);
                  double sl = iHigh(_Symbol,PERIOD_M5,highest);
                  sl = NormalizeDouble(sl,_Digits);
                  
                  if(sl < PositionGetDouble(POSITION_SL)){
                     if(trade.PositionModify(posTicket,sl,0)){
                        
                     }
                  }
               }
            }
         }
      }
   }
   
   
   
   int orders = 0;
   for (int orderIndex = OrdersTotal()-1; orderIndex >= 0; orderIndex--){
      ulong orderTicket = OrderGetTicket(orderIndex);
      if (OrderSelect(orderTicket)){
         if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == Magic){
            if(OrderGetInteger(ORDER_TIME_SETUP) < TimeCurrent() - 30 * PeriodSeconds(PERIOD_M1)){
               trade.OrderDelete(orderTicket);
            }
            orders += 1 ;
         }
      }
   }
   
   
   if(trendDirection == 1){
      if(maFast[0] > maMid[0] && maMid[0] > maSlow[0]){
         if (bid <= maFast[0]){
            if(positions + orders <= 0){
               int indexHighest = iHighest(_Symbol, PERIOD_M5, MODE_HIGH, 5, 1);
               double highestPrice = iHigh(_Symbol, PERIOD_M5, indexHighest);
               highestPrice = NormalizeDouble(highestPrice,_Digits);
               
               int indexLowest = iLowest(_Symbol, PERIOD_M5, MODE_LOW, 5, 1);
               double lowestPrice = iLow(_Symbol, PERIOD_M5, indexLowest);
               lowestPrice = NormalizeDouble(lowestPrice,_Digits);
               
               double sl = iLow(_Symbol,PERIOD_M5, 0) + 30 * _Point;
               sl = NormalizeDouble(sl, _Digits);
               
               
               trade.BuyStop(lotsize,highestPrice,_Symbol,sl);

            }
         } 
      }  
   }else if (trendDirection == -1){
      if(maFast[0] < maMid[0] && maMid[0] < maSlow[0]){
         if (bid >= maFast[0]){
            if(positions + orders <=0){
               int indexHighest = iHighest(_Symbol, PERIOD_M5, MODE_HIGH, 5, 1);
               double highestPrice = iHigh(_Symbol, PERIOD_M5, indexHighest);
               highestPrice = NormalizeDouble(highestPrice,_Digits);
               
               int indexLowest = iLowest(_Symbol, PERIOD_M5, MODE_LOW, 5, 1);
               double lowestPrice = iLow(_Symbol, PERIOD_M5, indexLowest);
               lowestPrice = NormalizeDouble(lowestPrice,_Digits);
               
               double sl = iHigh(_Symbol,PERIOD_M5, 0) - 30 * _Point;
               sl = NormalizeDouble(sl, _Digits);
               
               
               trade.SellStop(lotsize,lowestPrice,_Symbol,sl);
            }
         }
      }
   }
   
   
   
   
   Comment(" Fast Trend MA: ", DoubleToString(maTrendFast[0],_Digits),
            "\n Slow Trend Ma: ", DoubleToString(maTrendSlow[0],_Digits),
            "\n Trend Direction: ", trendDirection,
            "\n",
            "\n Fast Ma: ", DoubleToString(maFast[0],_Digits),
            "\n Mid  Ma: ", DoubleToString(maMid[0],_Digits),
            "\n Slow Ma: ", DoubleToString(maSlow[0],_Digits),
            "\n",
            "\n Total Positions: ", positions,
            "\n Total Orders: ", orders,
            "\n Account_ballance", equity);
  }
