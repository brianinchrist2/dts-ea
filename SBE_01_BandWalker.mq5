//+------------------------------------------------------------------+
//|                                           SBE_01_BandWalker.mq5  |
//|                                     Hurst-Adaptive Band Walker   |
//+------------------------------------------------------------------+
#property copyright "R2D2"
#property version   "1.00"
#include <Trade\Trade.mqh>

input double LotSize = 0.01;
input int BBPeriod = 20;
input double BBDev = 2.0;
input int ADXPeriod = 14;
input double ATRMultiplier = 2.0;

CTrade trade;
int bbHandle, adxHandle, atrHandle;
datetime lastBar;

int OnInit() {
   bbHandle = iBands(_Symbol, _Period, BBPeriod, 0, BBDev, PRICE_CLOSE);
   adxHandle = iADX(_Symbol, _Period, ADXPeriod);
   atrHandle = iATR(_Symbol, _Period, 14);
   trade.SetExpertMagicNumber(202601);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   IndicatorRelease(bbHandle); 
   IndicatorRelease(adxHandle);
   IndicatorRelease(atrHandle);
}

void OnTick() {
   datetime time[1];
   if(CopyTime(_Symbol, _Period, 0, 1, time) <= 0) return;
   if(time[0] == lastBar) return;
   lastBar = time[0];

   double close[2], upper[2], lower[2], mid[1], adx[1], atr[1];
   if(CopyClose(_Symbol, _Period, 1, 2, close) <= 0) return;
   if(CopyBuffer(bbHandle, 1, 1, 2, upper) <= 0) return;
   if(CopyBuffer(bbHandle, 2, 1, 2, lower) <= 0) return;
   if(CopyBuffer(bbHandle, 0, 1, 1, mid) <= 0) return;
   if(CopyBuffer(adxHandle, 0, 1, 1, adx) <= 0) return;
   if(CopyBuffer(atrHandle, 0, 1, 1, atr) <= 0) return;

   // Manage open positions (Exit at midline to capture trend ending)
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL) == _Symbol) {
         long type = PositionGetInteger(POSITION_TYPE);
         if(type == POSITION_TYPE_BUY && close[1] < mid[0]) trade.PositionClose(ticket);
         if(type == POSITION_TYPE_SELL && close[1] > mid[0]) trade.PositionClose(ticket);
      }
   }

   if(PositionsTotal() > 0) return;

   // Entry Logic (ADX > 30 proxy for strong Hurst Trend)
   if(adx[0] > 30.0) {
      double sl_dist = atr[0] * ATRMultiplier;
      // close[0] is older, close[1] is newest closed bar
      if(close[0] <= upper[0] && close[1] > upper[1]) {
         trade.Buy(LotSize, _Symbol, 0, close[1] - sl_dist, 0, "BandWalker Up");
      }
      else if(close[0] >= lower[0] && close[1] < lower[1]) {
         trade.Sell(LotSize, _Symbol, 0, close[1] + sl_dist, 0, "BandWalker Down");
      }
   }
}