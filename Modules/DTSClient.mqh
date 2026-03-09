//+------------------------------------------------------------------+
//|                                                   DTSClient.mqh  |
//|  DTS Client Module with Native MT5 Execution Fallback            |
//+------------------------------------------------------------------+
#include "../Utilities/Logger.mqh"
#include "../SBE_2026.mqh"
#include <Trade\Trade.mqh>

class CDTSClient
{
private:
   CLogger  *m_logger;
   CTrade    m_trade;          // MT5 Standard Trade Class
   
   string    m_host;
   int       m_port;
   bool      m_useDTS;
   bool      m_fallback;
   double    m_maxLot;
   bool      m_enforceSL;

public:
   CDTSClient(string host, int port, bool useDTS, bool fallback, double maxLot, bool enforceSL, CLogger *logger)
   {
      m_host = host;
      m_port = port;
      m_useDTS = useDTS;
      m_fallback = fallback;
      m_maxLot = maxLot;
      m_enforceSL = enforceSL;
      m_logger = logger;
      
      m_trade.SetExpertMagicNumber(2026101); // Set a unique Magic Number
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   }
   
   ~CDTSClient() {}
   
   //--- Test connection to external service
   bool TestConnection()
   {
      if(!m_useDTS) return true;
      // In real scenario, implement WebRequest here to check 127.0.0.1:8000
      m_logger.Warning("DTS Service not found at " + m_host + ". Using Native MT5 mode.");
      return false; 
   }
   
   //--- Check if position exists for specific symbol
   bool HasOpenPosition(string symbol)
   {
      return PositionSelect(symbol);
   }
   
   //--- Core Execution Logic
   bool ExecuteTrade(string symbol, ENUM_DIRECTION dir, double vol, double entry, double sl, double tp, string comment)
   {
      // 1. Safety Check: Lot size limit
      double finalVol = (vol > m_maxLot) ? m_maxLot : vol;
      
      // 2. Try DTS first if enabled
      if(m_useDTS)
      {
         // Placeholder for external API Call
         // if(DTS_API_Call_Success) return true;
         m_logger.Error("DTS Execution failed. Checking fallback...");
      }
      
      // 3. Native MT5 Fallback
      if(!m_useDTS || m_fallback)
      {
         bool success = false;
         if(dir == DIRECTION_BUY)
            success = m_trade.Buy(finalVol, symbol, 0, sl, tp, comment);
         else if(dir == DIRECTION_SELL)
            success = m_trade.Sell(finalVol, symbol, 0, sl, tp, comment);
            
         if(success)
            m_logger.Info("Native MT5 Trade Sent: " + EnumToString(dir) + " " + DoubleToString(finalVol, 2) + " lots");
         else
            m_logger.Error("Native MT5 Execution Error: " + m_trade.ResultComment());
            
         return success;
      }
      
      return false;
   }
   
   //--- Close specific position
   void ClosePosition(string symbol)
   {
      if(PositionSelect(symbol))
      {
         if(m_trade.PositionClose(symbol))
            m_logger.Info("Position closed on " + symbol);
      }
   }
   
   //--- Emergency Close All
   void CloseAllPositions()
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
            m_trade.PositionClose(ticket);
      }
      m_logger.Warning("All positions closed by CDTSClient.");
   }
   
   void CheckConnection()
   {
      // Background heartbeat for DTS service
   }
};
