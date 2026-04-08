<?php
// 中獎號碼 API
// GET /winning.php           → 查詢所有期別的中獎號碼
// GET /winning.php?period=xxxx → 查詢指定期別的中獎號碼

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'db.php';

// 如果有帶 period 參數，只查該期；否則查全部
$period = $_GET['period'] ?? null;

if ($period) {
    $stmt = $pdo->prepare('SELECT * FROM winning_numbers WHERE period = ?');
    $stmt->execute([$period]);
} else {
    $stmt = $pdo->query('SELECT * FROM winning_numbers ORDER BY period DESC');
}

echo json_encode($stmt->fetchAll());
