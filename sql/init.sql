-- ==============================================
-- Real-time BTC/USD tick ingestion initialization script
-- TimescaleDB / Tiger Cloud
-- ==============================================

-- 1. 创建原始tick数据表
CREATE TABLE IF NOT EXISTS realtime_financial_ticks (
    time TIMESTAMPTZ NOT NULL,
    symbol TEXT NOT NULL,
    price DOUBLE PRECISION NOT NULL,
    volume DOUBLE PRECISION,
    exchange TEXT
);

-- 2. 转为Timescale Hypertable（时序分区超表，本项目核心特性）
SELECT create_hypertable('realtime_financial_ticks', 'time', if_not_exists => TRUE);

-- 可选：给symbol建立索引，加快按标的查询
CREATE INDEX IF NOT EXISTS idx_tick_symbol ON realtime_financial_ticks (symbol, time DESC);

-- 3. 创建【连续聚合物化视图】：1分钟 OHLC K线
-- time_bucket 按1分钟分组，自动计算开盘、最高、最低、收盘、tick数量
CREATE MATERIALIZED VIEW IF NOT EXISTS tick_1min
WITH (timescaledb.continuous) AS
SELECT
  time_bucket('1 minute', time) AS bucket,
  symbol,
  FIRST(price, time) AS open,
  MAX(price) AS high,
  MIN(price) AS low,
  LAST(price, time) AS close,
  COUNT(*) AS tick_count
FROM realtime_financial_ticks
GROUP BY bucket, symbol
WITH NO DATA;

-- 4. 给聚合视图增加索引，提升查询速度
CREATE INDEX IF NOT EXISTS idx_1min_symbol_bucket ON tick_1min (symbol, bucket DESC);

-- 5. 设置连续聚合自动刷新策略
-- 含义：每隔1分钟，刷新【2分钟前 ~ 1分钟前】区间的数据，避免处理未闭合的当前分钟数据
SELECT add_continuous_aggregate_policy('tick_1min',
    start_offset => INTERVAL '2 min',
    end_offset   => INTERVAL '1 min',
    schedule_interval => INTERVAL '1 min',
    if_not_exists => TRUE
);

-- ==============================================
-- 【查询示例】
-- ==============================================
-- 查询原始tick数据
-- SELECT * FROM realtime_financial_ticks ORDER BY time DESC LIMIT 10;

-- 查询1分钟K线聚合数据
-- SELECT * FROM tick_1min ORDER BY bucket DESC LIMIT 10;
