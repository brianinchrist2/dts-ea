//+------------------------------------------------------------------+
//|                                               SBE_2026.mq5 |
//|                        Sovereign Bollinger Engine (SBE-2026)     |
//|                                                Developed by R2D2 |
//+------------------------------------------------------------------+
#property copyright "R2D2"
#property link      ""
#property version   "1.00"
#property description "Sovereign Bollinger Engine (SBE-2026) - Multi-layer Bollinger Bands with regime detection, signal purification, and extreme execution protocols."
#property description "Integration with DTS service for trade execution."

//--- Includes
#include "SBE_2026.mqh"
#include "Modules/RegimeOracle.mqh"
#include "Modules/SignalPurifier.mqh"
#include "Modules/ExecutionEngine.mqh"
#include "Modules/RiskSentry.mqh"
#include "Modules/GlobalGating.mqh"
#include "Modules/DTSClient.mqh"
#include "Utilities/Logger.mqh"
#include "Utilities/ConfigManager.mqh"
#include "Utilities/Indicators.mqh"

//--- Input Parameters
// Global Gating
input bool   EnableTimeFilter = true;           // Enable trading time filter
input string AllowedTradingHours = "00:00-23:59"; // Trading hours (HH:MM-HH:MM)
input bool   EnableNewsFilter = false;          // Enable news filter (placeholder)

// Regime Oracle
input int    FDIPeriod = 30;                    // FDI calculation period
input double FDITrendThreshold = 1.4;           // FDI < this = Trend
input double FDIMeanRevThreshold = 1.6;         // FDI > this = Mean Reversion
input int    TIIPeriod = 14;                    // TII calculation period
input int    TIITrendThreshold = 80;            // TII > this = Strong Trend
input int    TIIRangeThreshold = 20;            // TII < this = Range

// Signal Purifier
input double VAFThreshold = 0.7;                // VAF minimum for signal
input double DABVRThreshold = 1.2;              // DABVR minimum for breakout
input bool   EnableOBC = true;                  // Enable Order Block Confluence
input int    OBCHigherTimeframe = PERIOD_H1;    // Higher timeframe for OBC

// Execution Engine
input bool   EnableVRABBP = true;               // Enable volatility adaptive BB parameters
input int    ATRPeriod = 14;                    // ATR period for volatility regime
input double ATRLowPercentile = 25.0;           // Low volatility percentile
input double ATRHighPercentile = 75.0;          // High volatility percentile

// Risk Sentry
input double DSSPLongMultiplier = 2.5;          // Long stop loss multiplier (σ)
input double DSSPShortMultiplier = 1.5;         // Short stop loss multiplier (σ)
input double BZDThreshold = 2.5;                // Bandwidth Z-Score threshold for exit
input double MADCBThreshold = 3.5;              // MAD-CB circuit breaker threshold (σ)

// DTS Integration
input string DTSHost = "127.0.0.1";             // DTS service host
input int    DTSPort = 8000;                    // DTS service port
input bool   UseDTSForExecution = true;         // Use DTS for trade execution
input bool   FallbackToNativeMT5 = true;        // Fallback to native MT5 if DTS fails
input double MaxLotSize = 0.01;                 // Maximum lot size (SAFE-03)
input bool   EnforceStopLoss = true;            // Enforce stop loss (SAFE-02)

//--- Global Variables
CRegimeOracle    *regimeOracle;
CSignalPurifier  *signalPurifier;
CExecutionEngine *executionEngine;
CRiskSentry      *riskSentry;
CGlobalGating    *globalGating;
CDTSClient       *dtsClient;
CLogger          *logger;
CConfigManager   *config;

datetime lastBarTime;
bool     isFirstTick = true;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize logger
   logger = new CLogger("SBE_2026", true);
   logger.Info("Initializing SBE-2026 Expert Advisor");
   
   // Initialize configuration manager
   config = new CConfigManager();
   
   // Initialize modules
   regimeOracle = new CRegimeOracle(FDIPeriod, FDITrendThreshold, FDIMeanRevThreshold,
                                    TIIPeriod, TIITrendThreshold, TIIRangeThreshold, logger);
   signalPurifier = new CSignalPurifier(VAFThreshold, DABVRThreshold, EnableOBC,
                                        OBCHigherTimeframe, logger);
   executionEngine = new CExecutionEngine(EnableVRABBP, ATRPeriod, ATRLowPercentile,
                                          ATRHighPercentile, logger);
   riskSentry = new CRiskSentry(DSSPLongMultiplier, DSSPShortMultiplier,
                                BZDThreshold, MADCBThreshold, logger);
   globalGating = new CGlobalGating(EnableTimeFilter, AllowedTradingHours,
                                    EnableNewsFilter, logger);
   
   // Initialize DTS client
   dtsClient = new CDTSClient(DTSHost, DTSPort, UseDTSForExecution, 
                              FallbackToNativeMT5, MaxLotSize, EnforceStopLoss, logger);
   
   // Test DTS connection
   if(UseDTSForExecution && !dtsClient.TestConnection())
   {
      logger.Error("DTS connection test failed. Falling back to native MT5.");
      if(!FallbackToNativeMT5)
         return INIT_FAILED;
   }
   
   // Initialize 5-second timer for OnTimer() loop
   EventSetTimer(5);
   
   lastBarTime = iTime(_Symbol, _Period, 0);
   isFirstTick = true;
   
   logger.Info("SBE-2026 initialization completed successfully");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   logger.Info("Deinitializing SBE-2026 Expert Advisor. Reason: " + IntegerToString(reason));
   
   // Kill timer properly
   EventKillTimer();
   
   // Delete modules with pointer checking to prevent terminal crash
   if(CheckPointer(dtsClient) == POINTER_DYNAMIC) delete dtsClient;
   if(CheckPointer(globalGating) == POINTER_DYNAMIC) delete globalGating;
   if(CheckPointer(riskSentry) == POINTER_DYNAMIC) delete riskSentry;
   if(CheckPointer(executionEngine) == POINTER_DYNAMIC) delete executionEngine;
   if(CheckPointer(signalPurifier) == POINTER_DYNAMIC) delete signalPurifier;
   if(CheckPointer(regimeOracle) == POINTER_DYNAMIC) delete regimeOracle;
   if(CheckPointer(config) == POINTER_DYNAMIC) delete config;
   if(CheckPointer(logger) == POINTER_DYNAMIC) delete logger;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime currentBarTime = iTime(_Symbol, _Period, 0);

   // Check for new bar (process on bar open)
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      isFirstTick = true;
   }
   
   // Only process at the beginning of each bar
   if(!isFirstTick) return;
   isFirstTick = false;
   
   // Global gating check
   if(!globalGating.IsTradingAllowed())
      return;
   
   // Step 1: Determine market regime
   ENUM_REGIME regime = regimeOracle.GetMarketRegime();
   logger.Debug("Current regime: " + EnumToString(regime));
   
   // Step 2: If in transition regime, do nothing
   if(regime == REGIME_TRANSITION)
      return;
   
   // Step 3: Check for existing positions
   if(dtsClient.HasOpenPosition(_Symbol))
   {
      // Monitor and manage existing positions
      ManageExistingPositions(regime);
      return;
   }
   
   // Step 4: Generate signals based on regime
   ENUM_DIRECTION signal = GenerateSignal(regime);
   
   // Step 5: Purify signal
   if(signal != DIRECTION_NONE && signalPurifier.IsSignalPure(signal, regime))
   {
      // Step 6: Execute trade with risk management
      ExecuteTrade(signal, regime);
   }
}

//+------------------------------------------------------------------+
//| Generate signal based on regime                                  |
//+------------------------------------------------------------------+
ENUM_DIRECTION GenerateSignal(ENUM_REGIME regime)
{
   ENUM_DIRECTION signal = DIRECTION_NONE;
   
   switch(regime)
   {
      case REGIME_TREND_UP:
         // Trend following logic: buy on pullback to lower band
         signal = executionEngine.TrendFollowingSignal(true);
         break;
         
      case REGIME_TREND_DOWN:
         // Trend following logic: sell on rally to upper band
         signal = executionEngine.TrendFollowingSignal(false);
         break;
         
      case REGIME_MEAN_REVERSION:
         // Mean reversion logic: sell at upper band, buy at lower band
         signal = executionEngine.MeanReversionSignal();
         break;
         
      case REGIME_TRANSITION:
         // No signal
         break;
   }
   
   return signal;
}

//+------------------------------------------------------------------+
//| Execute trade with risk management                               |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_DIRECTION direction, ENUM_REGIME regime)
{
   // Get adaptive parameters from execution engine
   BBParameters params = executionEngine.GetAdaptiveParameters();
   
   // Calculate entry price, stop loss, take profit using risk sentry
   TradeInfo trade = riskSentry.CalculateTradeLevels(direction, params);
   
   // Execute trade via DTS client or native MT5
   bool success = dtsClient.ExecuteTrade(_Symbol, direction, trade.volume,
                                         trade.entryPrice, trade.stopLoss,
                                         trade.takeProfit, "DMAS-API");
   
   if(success)
   {
      logger.Info(StringFormat("Trade executed: %s %s at %.5f, SL: %.5f, TP: %.5f",
                               _Symbol, direction == DIRECTION_BUY ? "BUY" : "SELL",
                               trade.entryPrice, trade.stopLoss, trade.takeProfit));
   }
   else
   {
      logger.Error("Trade execution failed");
   }
}

//+------------------------------------------------------------------+
//| Manage existing positions                                        |
//+------------------------------------------------------------------+
void ManageExistingPositions(ENUM_REGIME regime)
{
   // Check for exit signals (BZD, stop loss, take profit)
   if(riskSentry.CheckExitSignal(_Symbol, regime))
   {
      dtsClient.ClosePosition(_Symbol);
      logger.Info("Position closed due to exit signal");
   }
   
   // Check for circuit breaker (MAD-CB)
   if(riskSentry.CheckCircuitBreaker(_Symbol))
   {
      dtsClient.CloseAllPositions();
      logger.Warning("Circuit breaker triggered - all positions closed");
   }
}

//+------------------------------------------------------------------+
//| Timer function (optional)                                        |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Periodic tasks like updating DTS connection status
   if(UseDTSForExecution)
      dtsClient.CheckConnection();
}
