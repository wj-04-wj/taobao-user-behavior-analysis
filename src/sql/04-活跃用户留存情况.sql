-- 活跃用户留存情况 ：衡量用户“留下来还是走了”的核心指标，直接反映产品粘性
-- 1.留存率
-- 定义：某天来的新用户，在之后的第 N 天，还有多少比例回来
-- 次日留存率
-- 2.跳失率
-- 定义：只看了 1 个页面 就离开的用户比例
-- 留存率 这个留存率其实意义不大最好是分析具体商品或者商品类别
-- 但也能反映平台对用户的吸引力间接反映商品对用户的吸引

-- 一日留存率
select u1.dates as '日期',
COUNT(DISTINCT u1.user_id) AS '当天活跃用户',
COUNT(DISTINCT u2.user_id) AS '次日留存用户',
round(count(distinct u2.user_id)/count(distinct u1.user_id)*100,2) as '次日留存率'
from user_behavior u1
left join (
    select dates,user_id from user_behavior
    ) as u2
on u1.user_id=u2.user_id
and u2.dates = DATE_ADD(u1.dates, INTERVAL 1 DAY)
where behavior_type='pv'
group by u1.dates;  -- 3日留存，7日留存都可以

-- 3日内留存用户,留存率
SELECT
    a.dates AS 日期,
    COUNT(DISTINCT a.user_id) AS 当天活跃用户,
    COUNT(DISTINCT b.user_id) AS 3日内留存用户,
    ROUND(COUNT(DISTINCT b.user_id) / COUNT(DISTINCT a.user_id) * 100, 2) AS 3日内留存率
FROM (
    SELECT user_id, dates
    FROM user_behavior
    WHERE behavior_type = 'pv'
    GROUP BY user_id, dates
) a -- a表也筛选数据加快速率
LEFT JOIN (
    SELECT user_id, dates
    FROM user_behavior
    GROUP BY user_id, dates
) b
    ON a.user_id = b.user_id
    AND b.dates BETWEEN DATE_ADD(a.dates, INTERVAL 1 DAY)
                    AND DATE_ADD(a.dates, INTERVAL 3 DAY)
GROUP BY a.dates;

-- 更灵活 1日、3日、7日一次算出留存用户数
SELECT
    a.dates AS 日期,
    COUNT(DISTINCT a.user_id) AS 当天活跃用户,
    COUNT(DISTINCT CASE WHEN b.dates = DATE_ADD(a.dates, INTERVAL 1 DAY) THEN b.user_id END) AS 次日留存,
    COUNT(DISTINCT CASE WHEN b.dates BETWEEN DATE_ADD(a.dates, INTERVAL 1 DAY)
                             AND DATE_ADD(a.dates, INTERVAL 3 DAY) THEN b.user_id END) AS 3日内留存,
    COUNT(DISTINCT CASE WHEN b.dates BETWEEN DATE_ADD(a.dates, INTERVAL 1 DAY)
                             AND DATE_ADD(a.dates, INTERVAL 7 DAY) THEN b.user_id END) AS 7日内留存
FROM (
    SELECT user_id, dates
    FROM user_behavior
    WHERE behavior_type = 'pv'
    GROUP BY user_id, dates
) a
LEFT JOIN (
    SELECT user_id, dates
    FROM user_behavior
    GROUP BY user_id, dates
) b
    ON a.user_id = b.user_id
    AND b.dates > a.dates
GROUP BY a.dates;

-- 创建表保存查询结果
create table retention_rate (
    dates char(10) comment '日期',
    pv_users int(9) comment '当天活跃用户',
    retention_users int(9) comment '次日留存用户',
    retention_1 decimal(5,2)  comment '次日留存率'
);
insert into retention_rate
select u1.dates as '日期',
COUNT(DISTINCT u1.user_id) AS '当天活跃用户',
COUNT(DISTINCT u2.user_id) AS '次日留存用户',
round(count(distinct u2.user_id)/count(distinct u1.user_id)*100,2) as '次日留存率'
from user_behavior u1
left join (
    select dates,user_id from user_behavior
    ) as u2
on u1.user_id=u2.user_id
and u2.dates = DATE_ADD(u1.dates, INTERVAL 1 DAY)
where behavior_type='pv'
group by u1.dates;
select * from retention_rate limit 50;

-- 2.跳失率
-- （1）跳失用户数
select count(*)
from (
         select user_id
         from user_behavior
         where behavior_type='pv'
         group by user_id
         having count(*)=1
     ) u;

-- （2）跳失率 （跳失用户数 / 总浏览用户数）
select count(u.user_id)/sum(uv) from pv_uv_puv,
( select user_id
from user_behavior
where behavior_type='pv'
group by user_id
having count(*)=1
) u;