//+------------------------------------------------------------------+
//|                                         SBE_02_WickReversion.mq5 |
//|                                Liquidity Void & 3.5σ Wick Rev.   |
//+------------------------------------------------------------------+
#property copyright "R2D2"
#property version   "1.00"
#include <Trade\Trade.mqh>

input double LotSize = 0.01;
input int BBPeriod = 20;
input double BBDev = 3.5;
input int ADXPeriod = 14;

CTrade trade;
int bbHandle, adxHandle, atrHandle;
datetime lastBar;

int OnInit() {
   bbHandle = iBands(_Symbol, _Period, BBPeriod, 0, BBDev, PRICE_CLOSE);
   adxHandle = iADX(_Symbol, _Period, ADXPeriod);
   atrHandle = iATR(_Symbol, _Period, 14);
   trade.SetExpertMagicNumber(202602);
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

   double open[1], close[1], high[1], low[1];
   double upper[1], lower[1], mid[1], adx[1], atr[1];
   
   if(CopyOpen(_Symbol, _Period, 1, 1, open) <= 0) return;
   if(CopyClose(_Symbol, _Period, 1, 1, close) <= 0) return;
   if(CopyHigh(_Symbol, _Period, 1, 1, high) <= 0) return;
   if(CopyLow(_Symbol, _Period, 1, 1, low) <= 0) return;
   if(CopyBuffer(bbHandle, 1, 1, 1, upper) <= 0) return;
   if(CopyBuffer(bbHandle, 2, 1, 1, lower) <= 0) return;
   if(CopyBuffer(bbHandle, 0, 1, 1, mid) <= 0) return;
   if(CopyBuffer(adxHandle, 0, 1, 1, adx) <= 0) return;
   if(CopyBuffer(atrHandle, 0, 1, 1, atr) <= 0) return;

   // TP logic: Mean Reversion to middle band
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL) == _Symbol) {
         long type = PositionGetInteger(POSITION_TYPE);
         if(type == POSITION_TYPE_BUY && close[0] >= mid[0]) trade.PositionClose(ticket);
         if(type == POSITION_TYPE_SELL && close[0] <= mid[0]) trade.PositionClose(ticket);
      }
   }

   if(PositionsTotal() > 0) return;

   double body = MathAbs(close[0] - open[0]);
   double lowerWick = MathMin(open[0], close[0]) - low[0];
   double upperWick = high[0] - MathMax(open[0], close[0]);

   // Regime: Ranging (ADX < 25)
   if(adx[0] < 25.0) {
      // Long: touched 3.5 lower band, closed inside, long wick (Pinbar)
      if(low[0] < lower[0] && close[0] > lower[0] && lowerWick > body * 1.5) {
         double sl = low[0] - (atr[0] * 0.5);
         trade.Buy(LotSize, _Symbol, 0, sl, 0, "WickReversion Buy");
      }
      // Short: touched 3.5 upper band, closed inside, long wick
      else if(high[0] > upper[0] && close[0] < upper[0] && upperWick > body * 1.5) {
         double sl = high[0] + (atr[0] * 0.5);
         trade.Sell(LotSize, _Symbol, 0, sl, 0, "WickReversion Sell");
      }
   }
}