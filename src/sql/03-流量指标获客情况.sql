-- 流量指标：获客情况
-- 1.页面游览量 pv 总共看了多少次
-- 2.独立访客数 uv 总共来了多少人
-- 3.游览深度 pv/uv 平均每个人看了多少次 衡量用户粘性
/*
 PV	网站总热度	活动效果好不好
 UV	用户规模	    有多少人来了
 PV/UV浏览深度	用户粘性	来了的人有没有认真看，还是逛一下就走了
 */
-- 先创建临时表，截取一部分数据，查看情况再对原表下手
create table temp_behavior like taobao.user_behavior;-- 创建临时表
insert into temp_behavior select  * from taobao.user_behavior limit 100000;-- 截取
select * from temp_behavior;
-- 由于我的数据是抽样处理的所以不需要进行以上操作
-- 整体指标：pv ,uv ,pv/uv 由于抽样数据很小所以效果一般（可能每个用户只抽取到一条数据）
select count(*) as pv, -- 89745
       count(distinct user_id) as uv, -- 82286
       round(count(*)/count(distinct user_id),2) as 'pv/uv' -- 1.096
from user_behavior
where behavior_type='pv';

-- 每日指标 当天有游览行为pv
select dates,
       count(*) as pv, -- 89745
       count(distinct user_id) as uv, -- 82286
       round(count(*)/count(distinct user_id),2) as 'pv/uv' -- 1.096
from user_behavior
where behavior_type='pv'
group by dates; -- 从2017-11-25 到 2017-12-03

-- 建表存储查询结果
create table pv_uv_puv(
    dates char(10) COMMENT '日期',
    pv int(9) COMMENT '页面浏览量',
    uv int(9) COMMENT '独立访客数（浏览用户）' ,
    puv decimal(10,2) COMMENT '人均浏览页数'
);
insert into  pv_uv_puv
select dates,
       count(*) as pv, -- 89745
       count(distinct user_id) as uv, -- 82286
       round(count(*)/count(distinct user_id),2) as 'pv/uv' -- 1.096
from user_behavior
where behavior_type='pv'
group by dates;
select * from pv_uv_puv ;
