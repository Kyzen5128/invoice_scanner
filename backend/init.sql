-- 建立發票資料庫與資料表
-- 執行方式: C:\xampp\mysql\bin\mysql.exe -u root < init.sql

CREATE DATABASE IF NOT EXISTS invoice_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE invoice_db;

DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS winning_numbers;

CREATE TABLE invoices (
  id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_number VARCHAR(20) NOT NULL,
  period VARCHAR(10) NOT NULL,
  amount INT DEFAULT 0,
  invoice_date DATE,
  image_path VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_invoice (invoice_number, period)
);

CREATE TABLE winning_numbers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  period VARCHAR(10) NOT NULL,
  prize_type VARCHAR(20) NOT NULL,
  number VARCHAR(20) NOT NULL,
  prize_amount INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO winning_numbers (period, prize_type, number, prize_amount) VALUES
('11304', '特別獎', 'WR-73786487', 2000000),
('11304', '六獎',   'UW-15342109', 10000);
