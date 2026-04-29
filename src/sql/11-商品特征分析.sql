/*
 * 注意：本分析基于抽样数据（约10万条），加购和购买样本量较小。
 * 加购率和加购购买率的计算结果仅供参考分析流程，不代表全量数据的真实值。
 * 在完整数据集上运行时，建议过滤加购人数 < 10 的品类，以提高结果的稳定性。
 */
 /*
 最热门的品类（浏览量最高）
 转化率最高的品类
 加购率高但购买率低的品类（用户犹豫）
 */
-- 加购率高但购买率低的品类（用户犹豫）
-- 加购人数太少的品类（比如只有 1 个人加购），加购购买率可能是 100% 或 0%，没有参考意义
-- 优化
-- COUNT(DISTINCT CASE WHEN behavior_type = 'cart' THEN user_id END) AS 加购人数
-- HAVING 加购人数 >= 10   -- 只统计加购人数 ≥ 10 的品类
-- NULLIF(表达式1, 表达式2) 1=2-->null 1!=2-->1 这里防止分母为零
-- 涉及除法的需要注意加上NULLIF防止分母为零

SELECT
    category_id,
    ROUND(COUNT(DISTINCT CASE WHEN behavior_type = 'cart' THEN user_id END) /
          NULLIF(COUNT(DISTINCT CASE WHEN behavior_type = 'pv' THEN user_id END), 0) * 100, 2) AS 加购率,
    ROUND(COUNT(DISTINCT CASE WHEN behavior_type = 'buy' THEN user_id END) /
          NULLIF(COUNT(DISTINCT CASE WHEN behavior_type = 'cart' THEN user_id END), 0) * 100, 2) AS 加购购买率
FROM user_behavior
GROUP BY category_id
ORDER BY 加购率 DESC,加购购买率
limit 10;

-- 验证
select * from taobao.user_behavior
where category_id=1171434;