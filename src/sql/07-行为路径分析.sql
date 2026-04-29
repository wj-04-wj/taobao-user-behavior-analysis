-- 行为路径分析
-- powerbi可视化可以用到桑基图：显示用户从哪个节点流向哪个节点
-- 分解树：逐级下钻，看不同路径的转化率
/*
 大多数人是“浏览→购买”	     说明商品详情页转化好，保持
 很多人“浏览→收藏→没买”	     用户有兴趣但犹豫，可以发优惠券提醒
 很多人“浏览→加购→没买”	     加购了但没结算，可以推送“你还有商品未支付”
 很多人“收藏→购买”占比高	说明收藏功能很重要，优化收藏体验
 */
/*
 思路分析：
 知晓用户的行为路径就可以知晓用户是否购买商品以及经过哪些行为下单商品
 首先我们需要对每个用户以及对应商品分析那么必然要对这两个字段进行分组
 我们需要知晓用户做了哪些事那么就要分组统计用户的各类行为case when统计
 然后对这些行为进行标准化（行为数量大于1说明发生过这类行为标记为1否则为0）
 将标记好的行为进行拼接concat(同一行的数据)构成路径(0001 1000.....)
 所以这里更加说明了为什么用户行为是分开统计成4列
 拼接的时候可以加上条件购买>0也可以不加因为不论怎样路径已经构建完成
 最后就是使数据更加直观创建人话表将路径一一对应
 注意中间查询过程中的数据可以不保存为表而是保存为视图
 因为我们只需要最终表进行数据分析
 这样的数据反而更加适合做出真实准确的漏斗表
 */

-- 统计用户对各个商品发生了哪些行为

-- 方法一使用sum
-- behavior_type = 'pv' 在 MySQL 中返回 1（真）或 0（假），SUM() 直接累加
-- 相等于SUM(if(behavior_type = 'pv',1,0)) AS pv
select user_id,item_id,
       sum(behavior_type='pv') as 'pv',
       sum(behavior_type='fav') as 'fav',
       sum(behavior_type='cart') as 'cart',
       sum(behavior_type='buy') as 'buy'
from taobao.user_behavior
group by user_id,item_id;

-- 方法二使用count+if
select user_id,item_id
,count(if(behavior_type='pv',behavior_type,null)) 'pv'
,count(if(behavior_type='fav',behavior_type,null)) 'fav'
,count(if(behavior_type='cart',behavior_type,null)) 'cart'
,count(if(behavior_type='buy',behavior_type,null)) 'buy'
from taobao.user_behavior
group by user_id,item_id;

-- 将结果存储为视图(相当于代码的别名)
create view user_behavior_view as
select user_id,item_id,
       sum(behavior_type='pv') as 'pv',
       sum(behavior_type='fav') as 'fav',
       sum(behavior_type='cart') as 'cart',
       sum(behavior_type='buy') as 'buy'
from taobao.user_behavior
group by user_id,item_id;

-- 用户行为标准化(或者说将结果更明了)
-- if语句
select user_id,item_id,
       if(pv,1,0) as 浏览了,
       if(fav,1,0) as 收藏了,
       if(cart,1,0) as 加购了,
       if(buy,1,0) as 购买了
from user_behavior_view;

-- case when语句并存储为视图
create view user_behavior_standard as
select user_id
,item_id
,(case when pv>0 then 1 else 0 end) 浏览了
,(case when fav>0 then 1 else 0 end) 收藏了
,(case when cart>0 then 1 else 0 end) 加购了
,(case when buy>0 then 1 else 0 end) 购买了
from user_behavior_view;

-- 路径类型
-- 将用户行为标准化字段拼接为一行使用 concat()
-- CONCAT	拼接一行内的多个字段(同行不同列)
-- GROUP_CONCAT	把多行的某个字段拼成一行(同列不同行)

-- GROUP_CONCAT方法是更为直接的方法而不需要将数据存为四列
select
    user_id,
    item_id,
    GROUP_CONCAT(behavior_type) AS 用户行为路径
from user_behavior
-- where user_id=646334 这一步验证代码没有问题
group by user_id, item_id;

-- concat （基于有对应四列的行为数据视图）
select *,
concat(浏览了,收藏了,加购了,购买了) as 用户行为路径
from user_behavior_standard;

select *,
concat(浏览了,收藏了,加购了,购买了) as 购买路径类型
from user_behavior_standard
where 购买了>0;

-- 存储为视图
create view user_behavior_path as
select *,
concat(浏览了,收藏了,加购了,购买了) 用户行为路径
from user_behavior_standard ;

create view user_buy_path as
select *,
concat(浏览了,收藏了,加购了,购买了) as 购买路径类型
from user_behavior_standard
where 购买了>0;

-- 统计各类购买行为数量
-- 方法一：直接在user_buy_path图上查询
select 购买路径类型
,count(*) 数量
from user_buy_path
group by 购买路径类型
order by 数量 desc;

-- 方法二：使用用户行为路径统计可以使用substring锁定最后一位为1的
select 用户行为路径,
count(*) as 数量
from user_behavior_path
where substring(用户行为路径,4,1)=1
group by 用户行为路径
order by 数量 desc;

-- 存储为视图
create view path_count as
select 购买路径类型
,count(*) 数量
from user_buy_path
group by 购买路径类型
order by 数量 desc;

-- 这一步找到了一个user_id可以放在前面验证GROUP_CONCAT方法
select user_id from user_buy_path join
(select 购买路径类型,count(*) as 数量
from user_buy_path
group by 购买路径类型
order by 数量 limit 1) as t
on user_buy_path.购买路径类型=t.购买路径类型;

-- 人话表 ：效果更直观
create table renhua(
    path_type char(4),
    description varchar(40)
);

insert into renhua
values('0001','直接购买了'),
('1001','浏览后购买了'),
('0011','加购后购买了'),
('1011','浏览加购后购买了'),
('0101','收藏后购买了'),
('1101','浏览收藏后购买了'),
('0111','收藏加购后购买了'),
('1111','浏览收藏加购后购买了');
select * from renhua;

-- 将之前视图中的数据与人话表连接更直观
select * from path_count as p
join renhua  as r
on p.购买路径类型=r.path_type
order by 数量 desc;

-- 存储结果
create table path_result(
    path_type char(4),
    description varchar(40),
    num int);
insert into path_result
select path_type,description,数量 from path_count as p
join renhua  as r
on p.购买路径类型=r.path_type
order by 数量 desc;
select * from path_result;

-- 浏览后购买或者直接购买
select sum(buy)
from user_behavior_view
where buy>0 and fav=0 and cart=0;