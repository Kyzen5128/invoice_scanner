-- 建立發票資料庫與資料表
-- 執行方式: C:\xampp\mysql\bin\mysql.exe -u root < init.sql

-- 建立資料庫，使用 utf8mb4 以支援中文及特殊字元
CREATE DATABASE IF NOT EXISTS invoice_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE invoice_db;

-- 重新建立前先刪除舊資料表（注意：會清除所有資料）
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS winning_numbers;

-- 發票資料表：儲存掃描後的發票資訊
CREATE TABLE invoices (
  id INT AUTO_INCREMENT PRIMARY KEY,         -- 流水號，自動遞增
  invoice_number VARCHAR(20) NOT NULL,       -- 發票號碼（如 AB-12345678）
  period VARCHAR(10) NOT NULL,               -- 發票期別（如 11304 代表民國 113 年 3-4 月）
  amount INT DEFAULT 0,                      -- 發票金額（元）
  invoice_date DATE,                         -- 發票開立日期
  image_path VARCHAR(255),                   -- 發票圖片的儲存路徑
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- 資料建立時間
  UNIQUE KEY uniq_invoice (invoice_number, period) -- 同一期別內發票號碼不重複
);

-- 中獎號碼資料表：儲存每期統一發票的中獎號碼
CREATE TABLE winning_numbers (
  id INT AUTO_INCREMENT PRIMARY KEY,         -- 流水號，自動遞增
  period VARCHAR(10) NOT NULL,               -- 期別（如 11304）
  prize_type VARCHAR(20) NOT NULL,           -- 獎項名稱（如 特別獎、特獎、頭獎...六獎）
  number VARCHAR(20) NOT NULL,               -- 中獎號碼
  prize_amount INT NOT NULL,                 -- 獎金金額（元）
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP   -- 資料建立時間
);

-- 插入範例中獎號碼（113 年 3-4 月期）
INSERT INTO winning_numbers (period, prize_type, number, prize_amount) VALUES
('11304', '特別獎', 'WR-73786487', 2000000), 
('11304', '六獎',   'UW-15342109', 10000);     
