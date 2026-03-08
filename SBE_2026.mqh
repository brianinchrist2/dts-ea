//+------------------------------------------------------------------+
//|                                              SBE_2026.mqh |
//|                  Common definitions for SBE-2026 EA               |
//+------------------------------------------------------------------+

//--- Regime enumeration
enum ENUM_REGIME
{
   REGIME_TRANSITION,      // Transition/ambiguous
   REGIME_TREND_UP,        // Strong uptrend
   REGIME_TREND_DOWN,      // Strong downtrend
   REGIME_MEAN_REVERSION   // Mean reversion/range
};

//--- Direction enumeration
enum ENUM_DIRECTION
{
   DIRECTION_NONE,
   DIRECTION_BUY,
   DIRECTION_SELL
};

//--- Bollinger Band parameters structure
struct BBParameters
{
   int      maPeriod;
   double   stdDev;
   double   upperBand;
   double   lowerBand;
   double   middleBand;
};

//--- Trade information structure
struct TradeInfo
{
   ENUM_DIRECTION direction;
   double         volume;
   double         entryPrice;
   double         stopLoss;
   double         takeProfit;
   string         comment;
};

//--- DTS Order structure
struct DTSOrder
{
   long           orderId;
   string         symbol;
   double         volume;
   string         action;      // "buy" or "sell"
   string         orderType;   // "market" or "limit"
   double         entryPrice;
   double         stopLoss;
   double         takeProfit;
   string         status;
   datetime       openedAt;
   datetime       closedAt;
   double         realizedPnl;
   string         comment;
};

//--- Function return codes
enum ENUM_RETCODE
{
   RET_SUCCESS,
   RET_ERROR,
   RET_INVALID_PARAM,
   RET_DTS_CONNECTION_FAILED,
   RET_RISK_VIOLATION
};

//--- Constants
#define DTS_API_TIMEOUT 5000      // milliseconds
#define MAX_RETRIES     3
#define LOG_FILE        "SBE_2026.log"
