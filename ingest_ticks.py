import asyncio
import websockets
import json
import psycopg2
from dotenv import load_dotenv
import os
from datetime import datetime

load_dotenv()
TIGER_CONN = os.getenv("TIGER_CONN_STRING")
TD_API_KEY = os.getenv("TWELVEDATA_API_KEY")

# 数据库连接
conn = psycopg2.connect(TIGER_CONN)
cur = conn.cursor()

async def main():
    url = f"wss://ws.twelvedata.com/v1/quotes/price?apikey={TD_API_KEY}"
    print("🔌 正在连接 twelvedata WebSocket...")
    async with websockets.connect(url) as websocket:
        print("✅ WebSocket已连接！发送订阅指令 BTC/USD")
        # 订阅报文
        sub_msg = {
            "action": "subscribe",
            "params": {
                "symbols": "BTC/USD"
            }
        }
        await websocket.send(json.dumps(sub_msg))

        # 循环接收所有消息
        async for raw_msg in websocket:
            print(f"\n📩原始消息: {raw_msg}") # 重点：打印服务器返回的全部内容！
            try:
                data = json.loads(raw_msg)
                # 判断是不是tick价格数据
                if data.get("event") == "price":
                    symbol = data["symbol"]
                    price = float(data["price"])
                    ts = datetime.fromtimestamp(data["timestamp"])
                    volume = data.get("volume", 0)
                    exchange = data.get("exchange", "")
                    print(f"✅收到tick: {symbol} price={price}")
                    # 写入Timescale
                    sql = """INSERT INTO realtime_financial_ticks(time, symbol, price, volume, exchange)
                             VALUES (%s,%s,%s,%s,%s)"""
                    cur.execute(sql, (ts, symbol, price, volume, exchange))
                    conn.commit()
                    print("💾入库成功")
            except Exception as e:
                print(f"⚠️解析异常: {e}")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except Exception as e:
        print(f"❌主程序异常: {e}")
