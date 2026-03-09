//+------------------------------------------------------------------+
//|                                                RegimeOracle.mqh  |
//+------------------------------------------------------------------+
#include "../Utilities/Logger.mqh"
#include "../SBE_2026.mqh"

class CRegimeOracle
{
private:
   CLogger *m_logger;
   int      m_maHandle;
   int      m_adxHandle;
public:
   CRegimeOracle(int fdiPeriod, double fdiTrend, double fdiMeanRev,
                 int tiiPeriod, int tiiTrend, int tiiRange, CLogger *logger)
   {
      m_logger = logger;
      // Using a 50-period EMA for baseline trend direction
      m_maHandle = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
      // ADX (Period 14) to measure trend strength
      m_adxHandle = iADX(_Symbol, _Period, 14);
   }
   ~CRegimeOracle() 
   { 
      IndicatorRelease(m_maHandle); 
      IndicatorRelease(m_adxHandle);
   }
   
   ENUM_REGIME GetMarketRegime()
   {
      double ma[1], adx[1];
      if(CopyBuffer(m_maHandle, 0, 1, 1, ma) <= 0) return REGIME_TRANSITION;
      if(CopyBuffer(m_adxHandle, 0, 1, 1, adx) <= 0) return REGIME_TRANSITION;
      
      double close = iClose(_Symbol, _Period, 1);
      
      // ADX > 25 indicates a strong trending regime
      if(adx[0] > 25.0)
      {
         // Price relative to EMA determines the trend direction
         if(close > ma[0]) return REGIME_TREND_UP;
         if(close < ma[0]) return REGIME_TREND_DOWN;
      }
      
      // If ADX <= 25, we are in a ranging/choppy market
      return REGIME_MEAN_REVERSION;
   }
};
