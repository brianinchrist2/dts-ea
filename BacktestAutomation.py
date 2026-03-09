import os
import subprocess
import time
from datetime import datetime

# --- 配置 MT5 路径 (请确认您的 MT5 路径是否正确) ---
MT5_PATH = r"D:\mt5 A\terminal64.exe"
EXPERT_PATH = r"dts-ea" # 在 MQL5\Experts 下的相对路径
REPORTS_DIR = r"D:\mt5 A\MQL5\Files\BacktestReports"

if not os.path.exists(REPORTS_DIR):
    os.makedirs(REPORTS_DIR)

# --- 定义测试任务列表 ---
# Model 参数含义: 0-Every tick, 1-1 min OHLC, 2-Open price only, 4-Every tick based on real ticks
tasks = [
    {"name": "SBE_01_BandWalker", "symbol": "BTCUSD", "period": "M15", "model": 1},
    {"name": "SBE_02_WickReversion", "symbol": "BTCUSD", "period": "M15", "model": 4}, # 必须用真实Tick
    {"name": "SBE_03_SqueezeBreakout", "symbol": "EURUSD", "period": "M15", "model": 1},
    {"name": "SBE_04_OBCDefender", "symbol": "BTCUSD", "period": "M15", "model": 1}
]

def generate_ini(task):
    ini_content = f"""
[Tester]
Expert={EXPERT_PATH}\\{task['name']}.ex5
Symbol={task['symbol']}
Period={task['period']}
Deposit=500
Leverage=500
Model={task['model']}
Optimization=0
FromDate=2025.12.01
ToDate=2026.03.01
ForwardMode=0
Report={REPORTS_DIR}\\{task['name']}_Report
ReplaceReport=1
ShutdownTerminal=1
Visual=0
"""
    ini_path = os.path.join(os.getcwd(), f"tester_{task['name']}.ini")
    with open(ini_path, "w", encoding="utf-16") as f:
        f.write(ini_content)
    return ini_path

def run_backtest():
    print(f"🚀 开始自动化回测任务共 {len(tasks)} 项...")
    
    for task in tasks:
        print(f"--- 正在回测: {task['name']} ({task['symbol']}, {task['period']}) ---")
        ini_file = generate_ini(task)
        
        # 构造 MT5 命令行指令
        cmd = [MT5_PATH, f"/config:{ini_file}"]
        
        try:
            # 启动并等待完成 (MT5 会在回测结束后按 ShutdownTerminal=1 自动关闭)
            process = subprocess.run(cmd, check=True)
            print(f"✅ {task['name']} 回测完成。报表已生成至: {REPORTS_DIR}")
        except Exception as e:
            print(f"❌ {task['name']} 回测失败: {str(e)}")
        finally:
            if os.path.exists(ini_file):
                os.remove(ini_file)

if __name__ == "__main__":
    run_backtest()
    print("\n✨ 所有回测任务已执行完毕！请去报表目录查看结果。")
