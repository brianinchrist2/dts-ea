//+------------------------------------------------------------------+
//|                                              SignalPurifier.mqh  |
//+------------------------------------------------------------------+
#include "../Utilities/Logger.mqh"
#include "../SBE_2026.mqh"

class CSignalPurifier
{
private:
   CLogger *m_logger;
   int      m_rsiHandle;
public:
   CSignalPurifier(double vaf, double dabvr, bool obc, int timeframe, CLogger *logger)
   {
      m_logger = logger;
      // Initialize RSI (Period 14) for momentum confirmation
      m_rsiHandle = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   }
   ~CSignalPurifier() 
   {
      IndicatorRelease(m_rsiHandle);
   }
   
   bool IsSignalPure(ENUM_DIRECTION dir, ENUM_REGIME regime)
   {
      double rsi[1];
      if(CopyBuffer(m_rsiHandle, 0, 1, 1, rsi) <= 0) return false;
      
      // Analyze the last closed candle
      double open1 = iOpen(_Symbol, _Period, 1);
      double close1 = iClose(_Symbol, _Period, 1);
      double high1 = iHigh(_Symbol, _Period, 1);
      double low1 = iLow(_Symbol, _Period, 1);
      
      double body = MathAbs(close1 - open1);
      double range = high1 - low1;
      
      if(range == 0) return false; // Avoid division by zero
      
      if(dir == DIRECTION_BUY)
      {
         // 1. Candlestick Action: Must be a Bullish candle OR a Pinbar with a long lower wick
         bool isBullish = (close1 > open1);
         double lowerWick = MathMin(open1, close1) - low1;
         bool isPinbar = (lowerWick > body * 1.5) && (lowerWick > range * 0.4);
         
         // 2. Momentum filter: RSI shouldn't be heavily overbought
         bool rsiValid = (rsi[0] < 60.0); 
         
         if((isBullish || isPinbar) && rsiValid)
            return true;
      }
      else if(dir == DIRECTION_SELL)
      {
         // 1. Candlestick Action: Must be a Bearish candle OR a Pinbar with a long upper wick
         bool isBearish = (close1 < open1);
         double upperWick = high1 - MathMax(open1, close1);
         bool isPinbar = (upperWick > body * 1.5) && (upperWick > range * 0.4);
         
         // 2. Momentum filter: RSI shouldn't be heavily oversold
         bool rsiValid = (rsi[0] > 40.0);
         
         if((isBearish || isPinbar) && rsiValid)
            return true;
      }
      
      m_logger.Debug("Signal rejected by SignalPurifier.");
      return false;
   }
};
