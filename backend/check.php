<?php
// 對獎 API
// GET /check.php → 比對所有發票與中獎號碼，回傳中獎清單與總獎金

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'db.php';

// SQL JOIN：只有 period 和 number 都對上，才算中獎
// 依獎金由高到低排序
$stmt = $pdo->query('
    SELECT i.id, i.invoice_number, i.period, w.prize_type, w.prize_amount
    FROM invoices i
    JOIN winning_numbers w
      ON i.period = w.period
     AND i.invoice_number = w.number
    ORDER BY w.prize_amount DESC
');

$rows = $stmt->fetchAll();

// PDO 預設將所有欄位回傳為字串，需手動轉型為數字，否則 Flutter 解析會失敗
$winners = array_map(function($row) {
    $row['id']           = (int)$row['id'];
    $row['prize_amount'] = (int)$row['prize_amount'];
    return $row;
}, $rows);

$total_prize = array_sum(array_column($winners, 'prize_amount'));

echo json_encode([
    'count'       => count($winners),
    'total_prize' => (int)$total_prize,
    'winners'     => $winners,
]);
