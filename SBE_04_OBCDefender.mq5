//+------------------------------------------------------------------+
//|                                           SBE_04_OBCDefender.mq5 |
//|                             Multi-TF Order Block Confluence      |
//+------------------------------------------------------------------+
#property copyright "R2D2"
#property version   "1.00"
#include <Trade\Trade.mqh>

input double LotSize = 0.01;
input int BBPeriod = 20;
input double BBDev = 2.5;

CTrade trade;
int bbHandle;
datetime lastBar;

int OnInit() {
   bbHandle = iBands(_Symbol, _Period, BBPeriod, 0, BBDev, PRICE_CLOSE);
   trade.SetExpertMagicNumber(202604);
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

   if(PositionsTotal() > 0) return;

   double close[2], upper[2], lower[2], mid[1];
   if(CopyClose(_Symbol, _Period, 1, 2, close) <= 0) return;
   if(CopyBuffer(bbHandle, 1, 1, 2, upper) <= 0) return;
   if(CopyBuffer(bbHandle, 2, 1, 2, lower) <= 0) return;
   if(CopyBuffer(bbHandle, 0, 1, 1, mid) <= 0) return;

   // Fetch H4 data for Order Blocks (Highest/Lowest of last 20 H4 bars)
   double h4High[20], h4Low[20];
   if(CopyHigh(_Symbol, PERIOD_H4, 1, 20, h4High) <= 0) return;
   if(CopyLow(_Symbol, PERIOD_H4, 1, 20, h4Low) <= 0) return;
   
   double maxH4 = h4High[0];
   double minH4 = h4Low[0];
   for(int i=1; i<20; i++) {
      if(h4High[i] > maxH4) maxH4 = h4High[i];
      if(h4Low[i] < minH4) minH4 = h4Low[i];
   }
   
   double rangeH4 = maxH4 - minH4;
   double obTolerance = rangeH4 * 0.05; // 5% tolerance zone

   // Long: Close outside lower band AND near H4 Support (Order Block)
   if(close[0] >= lower[0] && close[1] < lower[1]) {
      if(close[1] <= minH4 + obTolerance) {
         trade.Buy(LotSize, _Symbol, 0, minH4 - obTolerance, mid[0], "OBC Buy");
      }
   }
   // Short: Close outside upper band AND near H4 Resistance (Order Block)
   else if(close[0] <= upper[0] && close[1] > upper[1]) {
      if(close[1] >= maxH4 - obTolerance) {
         trade.Sell(LotSize, _Symbol, 0, maxH4 + obTolerance, mid[0], "OBC Sell");
      }
   }
}