-- 用户转化率分析
-- 转化漏斗分析
-- 目标：计算从“浏览”到“购买”各环节的转化率，定位流失节点
/*
 购买转化率 = 购买用户数 ÷ 浏览用户数
 浏览→购买	购买人数 ÷ 浏览人数	整体转化率
 浏览→加购	加购人数 ÷ 浏览人数	吸引加购的能力
 加购→购买	购买人数 ÷ 加购人数	购物车结算能力
 */

-- 统计各类行为用户数
select behavior_type,
       count(distinct user_id) as user_num
from user_behavior
group by behavior_type
order by behavior_type desc;

-- 存储查询结果
create table behavior_user_num(
  behavior_type varchar(5),
  user_num int
);
insert into behavior_user_num
select behavior_type,
       count(distinct user_id) as user_num
from user_behavior
group by behavior_type
order by behavior_type desc;
select * from behavior_user_num;


