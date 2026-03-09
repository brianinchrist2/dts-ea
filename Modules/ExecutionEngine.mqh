//+------------------------------------------------------------------+
//|                                             ExecutionEngine.mqh  |
//+------------------------------------------------------------------+
#include "../Utilities/Logger.mqh"
#include "../SBE_2026.mqh"

class CExecutionEngine
{
private:
   CLogger *m_logger;
   int      m_bbHandle;
   
public:
   CExecutionEngine(bool adaptive, int atrPeriod, double atrLow, double atrHigh, CLogger *logger)
   {
      m_logger = logger;
      // Initialize Bollinger Bands (Period 20, Deviation 2.0)
      m_bbHandle = iBands(_Symbol, _Period, 20, 0, 2.0, PRICE_CLOSE);
   }
   ~CExecutionEngine() { IndicatorRelease(m_bbHandle); }
   
   ENUM_DIRECTION TrendFollowingSignal(bool isLong)
   {
      double lower[2], upper[2], close[2];
      
      // Get the last 2 bars of data (0 = current forming bar, 1 = last closed bar)
      if(CopyBuffer(m_bbHandle, 2, 1, 2, lower) <= 0) return DIRECTION_NONE;
      if(CopyBuffer(m_bbHandle, 1, 1, 2, upper) <= 0) return DIRECTION_NONE;
      if(CopyClose(_Symbol, _Period, 1, 2, close) <= 0) return DIRECTION_NONE;
      
      if(isLong)
      {
         // Buy signal: Previous close was below lower band, current close is above it (rebound)
         if(close[0] < lower[0] && close[1] > lower[1]) 
            return DIRECTION_BUY;
      }
      else
      {
         // Sell signal: Previous close was above upper band, current close is below it (rebound)
         if(close[0] > upper[0] && close[1] < upper[1]) 
            return DIRECTION_SELL;
      }
      
      return DIRECTION_NONE;
   }
   
   ENUM_DIRECTION MeanReversionSignal()
   {
      // Simplistic mean reversion: just take the opposite signals
      double lower[1], upper[1], close[1];
      CopyBuffer(m_bbHandle, 2, 1, 1, lower);
      CopyBuffer(m_bbHandle, 1, 1, 1, upper);
      CopyClose(_Symbol, _Period, 1, 1, close);
      
      if(close[0] <= lower[0]) return DIRECTION_BUY;
      if(close[0] >= upper[0]) return DIRECTION_SELL;
      
      return DIRECTION_NONE;
   }
   
   BBParameters GetAdaptiveParameters()
   {
      BBParameters params;
      params.maPeriod = 20;
      params.stdDev = 2.0;
      return params;
   }
};
