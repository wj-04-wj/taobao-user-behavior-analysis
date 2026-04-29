-- 商品按热度分类
-- 热门和冷门
-- 商品按整体热度和同类商品中的热度分别分类，从而识别出“爆款”和“品类内的潜力款”
-- 还有哪类商品火爆
-- 按商品的总浏览量来分

-- 哪类商品
-- 方法一
select category_id,count(*) as '品类浏览量'
from user_behavior
where behavior_type='pv'
group by category_id
order by 2 desc
limit 10;
-- 方法二
select category_id ,sum(behavior_type='pv') '品类浏览量'
from user_behavior
group by category_id
order by 2 desc
limit 10;
-- 方法三
select category_id
,count(if(behavior_type='pv',behavior_type,null)) '品类浏览量'
from user_behavior
GROUP BY category_id
order by 2 desc
limit 10;

-- 哪个商品（整体）
-- 方法一
select item_id,count(*) as '商品浏览量'
from user_behavior
where behavior_type='pv'
group by item_id
order by 2 desc
limit 10;
-- 方法二
select item_id
,count(if(behavior_type='pv',behavior_type,null)) '商品浏览量'
from user_behavior
GROUP BY item_id
order by 2 desc
limit 10;

-- 哪类中的哪个商品

-- 这段代码得到的是最热门的商品是属于哪类的
-- 全平台 Top 10 商品 (因为可能 10 个商品来自同一个热门品类	)
select category_id,item_id,count(*) as '品类商品浏览量'
from user_behavior
where behavior_type='pv'
group by category_id,item_id
order by 3 desc
limit 10;

-- 每个品类的 Top 1 商品（品类冠军）
select category_id,item_id,品类商品浏览量 from
(
select category_id,item_id
,count(if(behavior_type='pv',behavior_type,null)) '品类商品浏览量'
,rank()over(partition by category_id
order by count(if(behavior_type='pv',behavior_type,null)) desc) r
from user_behavior
GROUP BY category_id,item_id
order by 3 desc
) a
where a.r = 1
order by a.品类商品浏览量 desc
limit 10;

-- 存储查询结果
create table popular_categories(
category_id int,
pv int
);
create table popular_items(
item_id int,
pv int
);
create table popular_cateitems(
category_id int,
item_id int,
pv int
);

insert into popular_categories
select category_id,count(*) as '品类浏览量'
from user_behavior
where behavior_type='pv'
group by category_id
order by 2 desc
limit 10;
insert into popular_items
select item_id,count(*) as '商品浏览量'
from user_behavior
where behavior_type='pv'
group by item_id
order by 2 desc
limit 10;
insert into popular_cateitems
select category_id,item_id,品类商品浏览量 from
(
select category_id,item_id
,count(if(behavior_type='pv',behavior_type,null)) '品类商品浏览量'
,rank()over(partition by category_id
order by count(if(behavior_type='pv',behavior_type,null)) desc) r
from user_behavior
GROUP BY category_id,item_id
order by 3 desc
) a
where a.r = 1
order by a.品类商品浏览量 desc
limit 10;

select * from popular_cateitems;
select * from popular_categories;
select * from popular_items;