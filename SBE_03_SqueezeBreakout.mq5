//+------------------------------------------------------------------+
//|                                      SBE_03_SqueezeBreakout.mq5  |
//|                             London/NY Overlap Squeeze Breakout   |
//+------------------------------------------------------------------+
#property copyright "R2D2"
#property version   "1.00"
#include <Trade\Trade.mqh>

input double LotSize = 0.01;
input int BBPeriod = 20;
input double BBDev = 2.0;

CTrade trade;
int bbHandle;
datetime lastBar;

int OnInit() {
   bbHandle = iBands(_Symbol, _Period, BBPeriod, 0, BBDev, PRICE_CLOSE);
   trade.SetExpertMagicNumber(202603);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   IndicatorRelease(bbHandle);
}

void OnTick() {
   datetime time[1];
   if(CopyTime(_Symbol, _Period, 0, 1, time) <= 0) return;
   if(time[0] == lastBar) return;
   lastBar = time[0];

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   // Close at end of window (16:00)
   if(dt.hour >= 16) {
       for(int i = PositionsTotal() - 1; i >= 0; i--) {
          ulong ticket = PositionGetTicket(i);
          if(PositionGetString(POSITION_SYMBOL) == _Symbol) {
             trade.PositionClose(ticket);
          }
       }
   }

   if(PositionsTotal() > 0) return;

   // Active Window: 13:00 - 15:59 (Proxy for London/NY overlap)
   if(dt.hour >= 13 && dt.hour < 16) {
      double close[2], upper[22], lower[22];
      if(CopyClose(_Symbol, _Period, 1, 2, close) <= 0) return;
      if(CopyBuffer(bbHandle, 1, 1, 22, upper) <= 0) return;
      if(CopyBuffer(bbHandle, 2, 1, 22, lower) <= 0) return;
      
      // Calculate average BBW over last 20 bars (index 0 to 19)
      double sumBBW = 0;
      for(int i=0; i<20; i++) sumBBW += (upper[i] - lower[i]);
      double avgBBW = sumBBW / 20.0;
      
      // Current BBW is at index 21 (latest closed bar)
      double currentBBW = upper[21] - lower[21];
      
      // Check Squeeze: Current width < 70% of 20-period average
      bool isSqueeze = currentBBW < (avgBBW * 0.7); 
      
      if(isSqueeze) {
         double atrVal = currentBBW / 4.0; // Approximation of Stop Loss
         // Breakout Upside
         if(close[0] <= upper[20] && close[1] > upper[21]) {
            trade.Buy(LotSize, _Symbol, 0, close[1] - atrVal*2, 0, "SqueezeBreakout Buy");
         }
         // Breakout Downside
         else if(close[0] >= lower[20] && close[1] < lower[21]) {
            trade.Sell(LotSize, _Symbol, 0, close[1] + atrVal*2, 0, "SqueezeBreakout Sell");
         }
      }
   }
}