/*
 * 数据库与表初始化脚本
 * 
 * 目的：创建分析所需的数据库和原始数据表
 */

-- 1. 创建数据库（如果不存在）
CREATE DATABASE IF NOT EXISTS taobao;
USE taobao;

-- 2. 创建用户行为表
CREATE TABLE IF NOT EXISTS user_behavior (
    user_id INT(9) COMMENT '用户ID',
    item_id INT(9) COMMENT '商品ID',
    category_id INT(9) COMMENT '商品类目ID',
    behavior_type VARCHAR(5) COMMENT '行为类型：pv(点击/浏览), cart(加购), fav(收藏), buy(购买)',
    timestamp INT(14) COMMENT '行为时间戳（Unix时间戳）'
) COMMENT '淘宝用户行为记录表';