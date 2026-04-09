<?php
// 中獎號碼 API
// GET /winning.php              → 查詢所有期別的中獎號碼（依期別倒序）
// GET /winning.php?period=xxxx  → 查詢指定期別的中獎號碼
//
// 回傳格式（JSON 陣列）：
// [
//   { "id": 1, "period": "11304", "prize_type": "特別獎",
//     "number": "WR-73786487", "prize_amount": "2000000", "created_at": "..." },
//   ...
// ]

// 允許跨來源請求，Flutter App 從手機呼叫時需要
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// 瀏覽器跨來源預檢請求（OPTIONS），直接回應 200 不做資料查詢
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'db.php';

// 從 URL query string 取得期別篩選條件，例如 ?period=11304
// 若未帶參數則查詢全部期別
$period = $_GET['period'] ?? null;

if ($period) {
    // 使用 prepared statement 防止 SQL injection
    $stmt = $pdo->prepare('SELECT * FROM winning_numbers WHERE period = ?');
    $stmt->execute([$period]);
} else {
    // 全部查詢：依期別新到舊排序
    $stmt = $pdo->query('SELECT * FROM winning_numbers ORDER BY period DESC');
}

// 注意：PDO 預設將所有欄位回傳為字串，prize_amount 在 Flutter 端解析時需注意型別
echo json_encode($stmt->fetchAll());
