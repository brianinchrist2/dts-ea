//+------------------------------------------------------------------+
//|                                                GlobalGating.mqh  |
//+------------------------------------------------------------------+
#include "../Utilities/Logger.mqh"

class CGlobalGating
{
private:
   CLogger *m_logger;
public:
   CGlobalGating(bool enableTime, string hours, bool enableNews, CLogger *logger)
   {
      m_logger = logger;
   }
   ~CGlobalGating() {}
   
   bool IsTradingAllowed()
   {
      return true; // Placeholder
   }
};
