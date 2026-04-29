-- 用户定位
-- RFM模型
-- 指标——>分类
-- R (Recency - 最近一次消费)：用户最近一次来购物是什么时候
-- 离现在越近，用户越有可能被激活
-- F (Frequency - 消费频率)：用户在一段时间内买了多少次
-- 买得越频繁，用户忠诚度越高
-- M (Monetary - 消费金额)：用户一共花了多少钱
-- 花得越多，用户价值越高
-- 这里的数据没有消费金额可以将用户购买的商品种类代替
-- 如果只按照 F值 和 R值区分那么将用户区分为价值用户、保持用户、挽留用户、发展用户

-- 计算R值即最近购买时间
select user_id, max(datetimes) '最近购买时间'
from user_behavior
where behavior_type='buy'
group by user_id
order by 2 desc;

-- 计算F值即用户消费频率
select user_id,count(*) as '购买次数'
from user_behavior
where behavior_type='buy'
group by user_id
order by 2 desc;

-- 合并统一
select user_id,count(*) '购买次数',
       max(datetimes) '最近购买时间'
from user_behavior
where behavior_type='buy'
group by user_id
order by 2 desc,3 desc;

-- 将查询结果保存
create table rfm_model(
    user_id int,
    frequence int,
    recent date
);
insert into rfm_model
select user_id,count(*) '购买次数',
       max(datetimes) '最近购买时间'
from user_behavior
where behavior_type='buy'
group by user_id
order by 2 desc,3 desc;

select * from rfm_model limit 5;

-- 根据购买次数对用户进行分层
-- 新增一列计算F值（打分）
alter table rfm_model add  column fscore int;

-- 打分将fscore更新到表中(使用 casewhen 语句)
-- 可以先查询出用户购买次数的范围

select min(frequence),max(frequence)
from rfm_model;

-- 由于数据量不够所以这里的写法是针对原始数据
update rfm_model
set fscore = case
    when frequence between 100 and 262 then 5
    when frequence between 50 and 99 then 4
    when frequence between 20 and 49 then 3
    when frequence between  5 and 19 then 2
    else 1 end;

-- 根据最近购买时间对用户进行分层
-- 新增一列计算R值（打分）
alter table rfm_model add column rscore int;
update rfm_model
set rscore=case
    when recent = '2017-12-03' then 5
    when recent  in ('2017-12-01','2017-12-02') then 4
    when recent in ('2017-11-29','2017-11-30') then 3
    when recent in ('2017-11-27','2017-11-28') then 2
    else 1 end;-- 1分的就是11-25以及11-26的
select * from rfm_model limit 5;

-- 对用户进行分层
-- 这里分层的界限是F和R值的平均
-- 价值用户、保持用户、发展用户、挽留用户
-- 定义变量存储R和F的平均值
set @f_avg=null;
set @r_avg=null;
select avg(fscore) from rfm_model;
select avg(rscore) from rfm_model;
select avg(fscore) into @f_avg from rfm_model;
select avg(rscore) into @r_avg from rfm_model;

-- 分层标记
select * ,(case
    when fscore>=@f_avg and rscore>=@r_avg then '价值用户'
    when fscore>=@f_avg and rscore<=@r_avg then '保持用户'
    when fscore<=@f_avg and rscore>=@r_avg then '发展用户'
    when fscore<=@f_avg and rscore<=@r_avg then '挽留用户'
    end) as class
from rfm_model;
select * from rfm_model;

-- 插入数据
-- 先新建一列
alter table rfm_model add column class char(10);
update rfm_model
set class=case
    when fscore>=@f_avg and rscore>=@r_avg then '价值用户'
    when fscore>=@f_avg and rscore<=@r_avg then '保持用户'
    when fscore<=@f_avg and rscore>=@r_avg then '发展用户'
    when fscore<=@f_avg and rscore<=@r_avg then '挽留用户'
    end;
select * from rfm_model limit 5;

-- 这里的分层只是针对了购买用户
-- 统计各层次购买用户数
select class,count(*) from rfm_model
group by class; -- 只存在价值用户和保存用户
select  * from rfm_model where class=null;-- 未查询到数据说明全部进行标记了
select count(distinct user_id) from user_behavior
where behavior_type='buy'; -- 1951
select count(user_id) from rfm_model; -- 1951
select count(distinct user_id) from user_behavior; -- 91106