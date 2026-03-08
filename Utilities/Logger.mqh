//+------------------------------------------------------------------+
//|                                                      Logger.mqh  |
//+------------------------------------------------------------------+
class CLogger
{
private:
   string m_name;
   bool   m_enable;
   
public:
   CLogger(string name, bool enable) : m_name(name), m_enable(enable) {}
   ~CLogger() {}
   
   void Info(string msg)    { if(m_enable) Print("[INFO] ", m_name, ": ", msg); }
   void Error(string msg)   { if(m_enable) Print("[ERROR] ", m_name, ": ", msg); }
   void Warning(string msg) { if(m_enable) Print("[WARN] ", m_name, ": ", msg); }
   void Debug(string msg)   { if(m_enable) Print("[DEBUG] ", m_name, ": ", msg); }
};
