-- 行为情况分析
-- 时间序列分析
-- 统计日期-小时的行为
/*
 找用户活跃时段：看哪几个小时 pv 最高
找购买高峰：看哪几个小时 buy 最多等
运营决策：在高峰时段投放活动、推送消息
 */

-- 方法一 sum统计
-- behavior_type = 'pv' 在 MySQL 中返回 1（真）或 0（假），SUM() 直接累加
-- 相等于SUM(if(behavior_type = 'pv',1,0)) AS pv
select dates,hours,
      SUM(behavior_type = 'pv') AS pv,
    SUM(behavior_type = 'buy') AS buy,
    SUM(behavior_type = 'cart') AS cart,
    SUM(behavior_type = 'fav') AS fav
from user_behavior
group by dates,hours
order by dates,hours;

-- 方法二：count+使用if语句判断
select dates,hours
,count(if(behavior_type='pv',behavior_type,null)) 'pv'
,count(if(behavior_type='cart',behavior_type,null)) 'cart'
,count(if(behavior_type='fav',behavior_type,null)) 'fav'
,count(if(behavior_type='buy',behavior_type,null)) 'buy'
from user_behavior
group by dates,hours
order by dates,hours;

-- 建表保存查询结果
drop table date_hour_behavior;
create table date_hour_behavior(
    dates char(10),
    hours char(2),
    pv int,
    cart int,
    fav int,
    buy int
);

insert into date_hour_behavior
select dates,hours
,count(if(behavior_type='pv',behavior_type,null)) 'pv'
,count(if(behavior_type='cart',behavior_type,null)) 'cart'
,count(if(behavior_type='fav',behavior_type,null)) 'fav'
,count(if(behavior_type='buy',behavior_type,null)) 'buy'
from user_behavior
group by dates,hours
order by dates,hours;

select * from date_hour_behavior ;
select * from  taobao.user_behavior order by dates,hours limit 500;