-- 商品转化率分析
-- 商品转化率 = 购买人数 ÷ 浏览人数
-- 品类转化率 = 品类购买人数 ÷ 品类浏览人数
-- 商品转化率	某个商品好不好卖	购买该商品的人数 ÷ 浏览该商品的人数
-- 用户转化率	某个用户会不会下单	购买任意商品的用户数 ÷ 访问平台的用户数
/*
 某个商品浏览量高但转化率低	优化详情页、降价、加好评
 某个商品浏览量低但转化率高	给它更多曝光，可能成为爆款
 某个品类整体转化率低	    该品类可能不适合平台，减少推荐
 */
-- 由于使用的是抽样数据（约10万条），部分商品的浏览/购买样本量较小
-- 转化率计算结果仅供参考趋势，不代表全量数据的真实值

-- 特定商品转化率
select item_id,
       sum(behavior_type='pv') as 'pv',
       sum(behavior_type='fav') as 'fav',
       sum(behavior_type='cart') as 'cart',
       sum(behavior_type='buy') as 'buy'
     ,count(distinct if(behavior_type='buy',user_id,null))/count(distinct user_id) 商品转化率
from taobao.user_behavior
group by item_id
order by 商品转化率 desc;

select item_id
,count(if(behavior_type='pv',behavior_type,null)) 'pv'
,count(if(behavior_type='fav',behavior_type,null)) 'fav'
,count(if(behavior_type='cart',behavior_type,null)) 'cart'
,count(if(behavior_type='buy',behavior_type,null)) 'buy'
,count(distinct if(behavior_type='buy',user_id,null))/count(distinct user_id) 商品转化率
from taobao.user_behavior
group by item_id
order by 商品转化率 desc;

-- 存储查询结果
create table item_detail(
    item_id int,
    pv int,
    fav int,
    cart int,
    buy int,
    user_buy_rate float
);
insert into item_detail
select item_id,
       sum(behavior_type='pv') as 'pv',
       sum(behavior_type='fav') as 'fav',
       sum(behavior_type='cart') as 'cart',
       sum(behavior_type='buy') as 'buy'
      ,count(distinct if(behavior_type='buy',user_id,null))/count(distinct user_id) 商品转化率
from taobao.user_behavior
group by item_id
order by 商品转化率 desc;
select * from item_detail limit 10;

-- 品类转化率
create table category_detail(
category_id int,
pv int,
fav int,
cart int,
buy int,
user_buy_rate float);
insert into category_detail
select category_id,
       sum(behavior_type='pv') as 'pv',
       sum(behavior_type='fav') as 'fav',
       sum(behavior_type='cart') as 'cart',
       sum(behavior_type='buy') as 'buy'
      ,count(distinct if(behavior_type='buy',user_id,null))/count(distinct user_id) 品类转化率
from user_behavior
group by category_id
order by 品类转化率 desc;
select * from category_detail limit 10;

-- 更为准确的是
-- 商品转化率 = 购买人数 ÷ 浏览人数
-- 品类转化率 = 品类购买人数 ÷ 品类浏览人数
select item_id,
       sum(behavior_type='pv') as 'pv',
       sum(behavior_type='fav') as 'fav',
       sum(behavior_type='cart') as 'cart',
       sum(behavior_type='buy') as 'buy'
     ,count(distinct if(behavior_type='buy',user_id,null))/count(distinct if(behavior_type='pv',user_id,null)) 商品转化率
from taobao.user_behavior
group by item_id
order by 商品转化率 desc;
select category_id,
       sum(behavior_type='pv') as 'pv',
       sum(behavior_type='fav') as 'fav',
       sum(behavior_type='cart') as 'cart',
       sum(behavior_type='buy') as 'buy'
     ,count(distinct if(behavior_type='buy',user_id,null))/count(distinct if(behavior_type='pv',user_id,null)) 品类转化率
from taobao.user_behavior
group by category_id
order by 品类转化率 desc;