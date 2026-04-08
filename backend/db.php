<?php
// 資料庫連線設定
// XAMPP MariaDB 預設：root 帳號、無密碼、port 3306

$host   = 'localhost';
$dbname = 'invoice_db';
$user   = 'root';
$pass   = '';

try {
    // PDO：PHP 內建的資料庫連線介面，支援 prepared statement 防止 SQL injection
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $user, $pass);

    // 有錯誤時直接丟出例外，方便偵錯
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // 查詢結果預設回傳關聯陣列（欄位名稱當 key）
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

} catch (PDOException $e) {
    // 連線失敗時直接回傳 500 錯誤，避免後續程式繼續跑
    http_response_code(500);
    echo json_encode(['error' => '資料庫連線失敗: ' . $e->getMessage()]);
    exit;
}
