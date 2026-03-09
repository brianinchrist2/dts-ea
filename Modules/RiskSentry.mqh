//+------------------------------------------------------------------+
//|                                                  RiskSentry.mqh  |
//+------------------------------------------------------------------+
#include "../Utilities/Logger.mqh"
#include "../SBE_2026.mqh"

class CRiskSentry
{
private:
   CLogger *m_logger;
   double   m_slMultiplier;
   int      m_atrHandle;
   
public:
   CRiskSentry(double longMult, double shortMult, double bzdThresh, double madcbThresh, CLogger *logger)
   {
      m_logger = logger;
      m_slMultiplier = longMult; // Use the multiplier for SL distance
      m_atrHandle = iATR(_Symbol, _Period, 14);
   }
   ~CRiskSentry() { IndicatorRelease(m_atrHandle); }
   
   TradeInfo CalculateTradeLevels(ENUM_DIRECTION dir, BBParameters &params)
   {
      TradeInfo info;
      info.direction = dir;
      info.volume = 0.01; // Base volume
      
      double atr[1];
      if(CopyBuffer(m_atrHandle, 0, 1, 1, atr) <= 0)
      {
         // Fallback distance if ATR fails
         atr[0] = 100 * _Point; 
      }
      
      double sl_dist = atr[0] * m_slMultiplier;
      
      if(dir == DIRECTION_BUY)
      {
         info.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         info.stopLoss = NormalizeDouble(info.entryPrice - sl_dist, _Digits);
         info.takeProfit = NormalizeDouble(info.entryPrice + (sl_dist * 2), _Digits); // 1:2 Risk Reward
      }
      else if(dir == DIRECTION_SELL)
      {
         info.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         info.stopLoss = NormalizeDouble(info.entryPrice + sl_dist, _Digits);
         info.takeProfit = NormalizeDouble(info.entryPrice - (sl_dist * 2), _Digits); // 1:2 Risk Reward
      }
      
      info.comment = "SBE_Auto";
      return info;
   }
   
   bool CheckExitSignal(string symbol, ENUM_REGIME regime)
   {
      return false; // Leave exit management to TP/SL for now
   }
   
   bool CheckCircuitBreaker(string symbol)
   {
      return false; 
   }
};
