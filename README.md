# Real-time-BTC-USD-Tick-Ingestion-Pipeline-with-TimescaleDB
Build a real-time BTC/USD tick ingestion pipeline, stream market tick data from TwelveData WebSocket into Timescale hypertable, support raw tick query and continuous aggregate 1min OHLC K-line.



复制 `.env.example` 重命名为 `.env`，填入自己的数据库连接串与 TwelveData API Key。





# 实时比特币/美元交易对报价摄取管道（TimescaleDB）
> Real-time BTC/USD Tick Ingestion Pipeline with TimescaleDB
Hacktoberfest 项目演示：基于 Python + WebSocket 实时抓取加密货币 Tick 行情，存入 TimescaleDB 时序数据库，支持原始Tick查询与自动聚合1分钟OHLC K线。

## 📖 项目简介
本项目搭建一套端到端金融时序数据流管线：
1. **数据源**：TwelveData WebSocket 实时行情流，订阅 Binance BTC/USD Tick 数据；
2. **采集程序**：Python 异步客户端，运行于 WSL2 Ubuntu，持续接收行情并写入数据库；
3. **时序存储**：Timescale Cloud（Tiger Cloud），使用 Hypertable 时序超表存储 Tick；
4. **时序分析**：利用 TimescaleDB 连续聚合（Continuous Aggregate）自动生成1分钟OHLC K线。

整条链路可以持续接收实时BTC价格Tick，持久化入库，支持通过标准SQL查询原始行情与聚合K线。

## 🏗️ 架构


TwelveData WebSocket (BTC/USD Tick)
↓
Python Async Collector (WSL2)
↓
TimescaleDB Hypertable（realtime_financial_ticks）
↓
Continuous Aggregate → 1 分钟 OHLC K 线视图
plaintext



## 🧰 技术栈
- Python 3.11
- `websockets`：异步 WebSocket 客户端
- `psycopg2`：PostgreSQL/TimescaleDB 数据库驱动
- `python-dotenv`：环境变量管理
- TimescaleDB (Timescale Cloud / Tiger Cloud)
- WSL2 Ubuntu
- TwelveData WebSocket API

## 📋 前置准备
1. 注册 TwelveData，获取 API Key
2. 开通 Timescale Cloud（Tiger Cloud）实例，拿到数据库连接串
3. WSL2 环境安装依赖
```bash
pip install websockets psycopg2-binary python-dotenv


部署步骤
1. 环境配置
复制 .env.example，重命名为 .env，填入你的密钥信息
bash
￼
￼
cp
 .env.example .env
nano
 .env
￼
.env 文件内容示例：
env
￼
￼
TIGER_CONN_STRING="postgresql://用户名:密码@主机:端口/数据库名"
TWELVEDATA_API_KEY="你的TwelveData API Key"
￼
⚠️ 不要将 .env 提交到代码仓库！ 仓库仅保留 .env.example 模板。
2. 初始化数据库表结构
打开 Timescale Cloud SQL 编辑器，执行 sql/init.sql
脚本会自动完成：
• 创建原始 tick 数据表
• 转为 Timescale Hypertable 时序超表
• 创建索引优化查询
• 创建 1 分钟连续聚合 K 线视图 + 自动刷新策略
3. 启动实时采集程序
bash
￼
￼
python3 ingest_ticks.py
￼
终端输出 入库成功 即代表行情正在持续写入数据库。
按 Ctrl + C 停止采集。
🔍 查询示例
查询原始 Tick 明细
sql
￼
￼
SELECT * FROM realtime_financial_ticks ORDER BY time DESC LIMIT 10;
￼
查询自动聚合的 1 分钟 OHLC K 线
sql
￼
￼
SELECT * FROM tick_1min ORDER BY bucket DESC LIMIT 10;
