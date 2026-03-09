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
      
      // Get the last 2 closed bars (index 1 and 2)
      // Array mapping: [0] = bar index 2 (older), [1] = bar index 1 (latest closed)
      if(CopyBuffer(m_bbHandle, 2, 1, 2, lower) <= 0) return DIRECTION_NONE;
      if(CopyBuffer(m_bbHandle, 1, 1, 2, upper) <= 0) return DIRECTION_NONE;
      if(CopyClose(_Symbol, _Period, 1, 2, close) <= 0) return DIRECTION_NONE;
      
      if(isLong)
      {
         // Buy signal: Pullback touching lower band, returning inside
         if(close[0] < lower[0] && close[1] > lower[1]) 
            return DIRECTION_BUY;
      }
      else
      {
         // Sell signal: Rally touching upper band, returning inside
         if(close[0] > upper[0] && close[1] < upper[1]) 
            return DIRECTION_SELL;
      }
      
      return DIRECTION_NONE;
   }
   
   ENUM_DIRECTION MeanReversionSignal()
   {
      double lower[2], upper[2], close[2];
      
      if(CopyBuffer(m_bbHandle, 2, 1, 2, lower) <= 0) return DIRECTION_NONE;
      if(CopyBuffer(m_bbHandle, 1, 1, 2, upper) <= 0) return DIRECTION_NONE;
      if(CopyClose(_Symbol, _Period, 1, 2, close) <= 0) return DIRECTION_NONE;
      
      // Buy: previous close outside/touching lower, current close back inside
      if(close[0] <= lower[0] && close[1] > lower[1]) return DIRECTION_BUY;
      
      // Sell: previous close outside/touching upper, current close back inside
      if(close[0] >= upper[0] && close[1] < upper[1]) return DIRECTION_SELL;
      
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
