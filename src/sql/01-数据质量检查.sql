/*
 * 数据质量检查
 * 
 * 目的：验证原始数据的完整性、时间范围和基本分布
 * 数据表：user_behavior
 * 关键字段：user_id, behavior_type, timestamps
 */
 
-- 1.验证数据总数
-- 以便后续SQL操作保证数据准确性
SELECT COUNT(*) FROM user_behavior; -- 100151


-- 2.验证数据时间范围
-- 验证数据时间范围，确认分析周期，验证是否存在不合理数据
SELECT
    MIN(FROM_UNIXTIME(timestamps)) AS start_date,
    MAX(FROM_UNIXTIME(timestamps)) AS end_date
FROM user_behavior;
-- 2017-11-25 00:00:01--2017-12-03 23:59:52


-- 3.验证各行为类型数量
-- 了解各行为数据分布
SELECT
    behavior_type,
    COUNT(*) AS cnt
FROM user_behavior
GROUP BY behavior_type;
-- pv-89745 cart-5473 buy-1956 fav-2917