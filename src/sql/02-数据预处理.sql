/*
 * 淘宝用户行为数据预处理
 * 目标：清洗原始数据，构建分析用宽表
 */

-- 数据预处理
-- 1.改变字段名(避免关键字冲突) 使用alter语句
alter table user_behavior change timestamp timestamps int(14);

-- 2.检查数据是否有空值 
-- 方法一：使用 case when语句
SELECT
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user,
    SUM(CASE WHEN item_id IS NULL THEN 1 ELSE 0 END) AS null_item,
    SUM(CASE WHEN category_id IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN behavior_type IS NULL THEN 1 ELSE 0 END) AS null_behavior,
    SUM(CASE WHEN `timestamps` IS NULL THEN 1 ELSE 0 END) AS null_ts
FROM user_behavior; -- 没有空值

-- 方法二：使用if语句+isnull （更简洁）
select
sum(if(user_id IS NULL ,1,0)) as null_user,
sum(if(item_id IS NULL ,1,0))  as null_item,
sum(if(category_id IS NULL ,1,0)) as null_category,
sum(if(behavior_type IS NULL ,1,0)) as null_behavior,
sum(if(timestamps IS NULL ,1,0)) as null_ts
from user_behavior;

-- 3.检查重复值
-- （1）先看有没有完全重复的行
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT CONCAT(user_id, item_id, category_id, behavior_type, timestamps)) AS unique_rows
FROM user_behavior; -- 如果两数相等，说明无完全重复行

-- （2）找出重复的行
select user_id,item_id,timestamps from user_behavior
group by user_id,item_id,timestamps
having count(*)>1; -- 这三个字段保证数据的唯一性，其实使用5个字段分组更稳妥

-- 4.去重
-- 方法一
-- (1)先创建一个临时表，保留每个重复组的第一条
CREATE TABLE user_behavior_dedup AS
SELECT * FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY user_id, item_id, category_id, behavior_type, timestamps
               ORDER BY timestamps
           ) AS rn
    FROM user_behavior
) t WHERE rn = 1;

-- (2)检查新表行数
SELECT COUNT(*) FROM user_behavior_dedup;

-- (3)确认没问题后，替换原表
DROP TABLE user_behavior;
ALTER TABLE user_behavior_dedup RENAME TO user_behavior;

-- 方法二 运行速率可能过慢
-- （1）加 id 列放在第一列
ALTER TABLE user_behavior ADD COLUMN id INT FIRST;
SELECT id FROM user_behavior LIMIT 5;-- 查看id有没有值

-- （2）把 id 设为主键并自增
ALTER TABLE user_behavior MODIFY COLUMN id INT PRIMARY KEY AUTO_INCREMENT;

-- （3）自连接删除重复行
delete user_behavior from
user_behavior,
(
select user_id,item_id,timestamps,min(id) id from user_behavior
group by user_id,item_id,timestamps
having count(*)>1
) t2
where user_behavior.user_id=t2.user_id
and user_behavior.item_id=t2.item_id
and user_behavior.timestamps=t2.timestamps
and user_behavior.id>t2.id; -- 将原表中重复数据的id不为最小的行数据删除

-- （4）查看总行数变化
SELECT COUNT(*) FROM user_behavior;

-- （5）检查是否还有重复
SELECT
    user_id, item_id, timestamps, COUNT(*) AS dup_count
FROM user_behavior
GROUP BY user_id, item_id, timestamps
HAVING dup_count > 1;

-- 5.去除异常值
delete from user_behavior
where FROM_UNIXTIME(timestamps) < '2017-11-25 00:00:00'
or FROM_UNIXTIME(timestamps)> '2017-12-03 23:59:59';
-- 直接用数据戳比较
-- (1)验证时间戳范围
SELECT UNIX_TIMESTAMP('2017-11-25 00:00:00');   -- 结果 1511539200
SELECT UNIX_TIMESTAMP('2017-12-03 23:59:59');   -- 结果 1512345599

-- (2)删除前先确认数量
SELECT COUNT(*) FROM user_behavior
WHERE timestamps < 1511539200 OR timestamps > 1512345599; -- 数据量55

-- (3)删除异常数据
DELETE FROM user_behavior
WHERE timestamps < 1511539200 OR timestamps > 1512345599;

-- 6.新增日期字段 ： date time hour
show VARIABLES like '%_buffer%'; -- 查看缓冲值够不够用
set GLOBAL innodb_buffer_pool_size=1070000000; -- 不够用更改缓冲值运行之后重启mysql
-- (1) 添加新列 datetimes 并将其转为日期类型
alter table user_behavior add datetimes TIMESTAMP(0); -- 表示秒之后的不要
update user_behavior set datetimes=FROM_UNIXTIME(timestamps);
select * from user_behavior limit 5;

-- (2) 添加新列 dates,times,hours
ALTER TABLE user_behavior ADD COLUMN dates char(10); -- DATE
ALTER TABLE user_behavior ADD COLUMN times char(8);  -- TIME
ALTER TABLE user_behavior ADD COLUMN hours char(2);  -- HOUR
UPDATE user_behavior
SET dates = date(datetimes),
    times = time(datetimes),
    hours = HOUR(datetimes);
update user_behavior set hours=substring(datetimes,12,2); -- 这里使用字符串切分可以让后续的可视化更方便

-- (3)验证数据时间范围
SELECT
    MIN(FROM_UNIXTIME(timestamps)) AS start_date,
    MAX(FROM_UNIXTIME(timestamps)) AS end_date
FROM user_behavior;