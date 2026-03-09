//+------------------------------------------------------------------+
//|                                                RegimeOracle.mqh  |
//+------------------------------------------------------------------+
#include "../Utilities/Logger.mqh"
#include "../SBE_2026.mqh"

class CRegimeOracle
{
private:
   CLogger *m_logger;
   int      m_fdiPeriod;
   int      m_maHandle;
public:
   CRegimeOracle(int fdiPeriod, double fdiTrend, double fdiMeanRev,
                 int tiiPeriod, int tiiTrend, int tiiRange, CLogger *logger)
   {
      m_logger = logger;
      m_fdiPeriod = fdiPeriod;
      // Initialize a Simple Moving Average for basic trend detection
      m_maHandle = iMA(_Symbol, _Period, m_fdiPeriod, 0, MODE_SMA, PRICE_CLOSE);
   }
   ~CRegimeOracle() { IndicatorRelease(m_maHandle); }
   
   ENUM_REGIME GetMarketRegime()
   {
      double ma[1];
      if(CopyBuffer(m_maHandle, 0, 1, 1, ma) <= 0) return REGIME_TRANSITION;
      
      double close = iClose(_Symbol, _Period, 1);
      
      // Basic regime logic: Price above MA = Uptrend, Below MA = Downtrend
      if(close > ma[0]) return REGIME_TREND_UP;
      if(close < ma[0]) return REGIME_TREND_DOWN;
      
      return REGIME_MEAN_REVERSION;
   }
};
