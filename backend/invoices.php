<?php
// 發票 API
// GET    /invoices.php              → 查詢所有發票
// POST   /invoices.php              → 新增或更新一張發票
// DELETE /invoices.php?number=xxxx  → 依發票號碼刪除

// 允許跨來源請求（Flutter App 需要）
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// 瀏覽器在跨來源請求前會先送 OPTIONS 預檢請求，直接回應 200 即可
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

// ─── GET：查詢所有發票 ────────────────────────────────────────────
if ($method === 'GET') {
    $stmt = $pdo->query('SELECT * FROM invoices ORDER BY created_at DESC');
    $rows = $stmt->fetchAll();

    // 將數字欄位從字串轉型為整數，確保 Flutter 端型別正確
    $rows = array_map(function($row) {
        $row['id']     = (int)$row['id'];
        $row['amount'] = (int)$row['amount'];
        return $row;
    }, $rows);

    echo json_encode($rows);

// ─── POST：新增或更新發票 ─────────────────────────────────────────
} elseif ($method === 'POST') {

    // 從請求 body 讀取 JSON 資料
    $body           = json_decode(file_get_contents('php://input'), true);
    $invoice_number = $body['invoice_number'] ?? null;
    $period         = $body['period']         ?? null;
    $amount         = $body['amount']         ?? 0;
    $invoice_date   = $body['invoice_date']   ?? null;
    $image_path     = $body['image_path']     ?? null;

    // 發票號碼和期別是必填欄位
    if (!$invoice_number || !$period) {
        http_response_code(400);
        echo json_encode(['error' => 'invoice_number and period are required']);
        exit;
    }

    // 先查看這張發票是否已存在（用 invoice_number + period 做唯一識別）
    $stmt = $pdo->prepare('SELECT id FROM invoices WHERE invoice_number = ? AND period = ?');
    $stmt->execute([$invoice_number, $period]);
    $existing = $stmt->fetch();

    if ($existing) {
        // 已存在 → 使用者可能修改了金額或日期，執行更新
        $stmt = $pdo->prepare(
            'UPDATE invoices SET amount=?, invoice_date=?, image_path=? WHERE invoice_number=? AND period=?'
        );
        $stmt->execute([$amount, $invoice_date, $image_path, $invoice_number, $period]);
        echo json_encode(['ok' => true, 'id' => (int)$existing['id']]);
    } else {
        // 不存在 → 第一次儲存，新增一筆
        $stmt = $pdo->prepare(
            'INSERT INTO invoices (invoice_number, period, amount, invoice_date, image_path) VALUES (?,?,?,?,?)'
        );
        $stmt->execute([$invoice_number, $period, $amount, $invoice_date, $image_path]);
        echo json_encode(['ok' => true, 'id' => (int)$pdo->lastInsertId()]);
    }

// ─── DELETE：依發票號碼刪除 ───────────────────────────────────────
} elseif ($method === 'DELETE') {

    // 發票號碼從 URL query string 讀取，例如 ?number=WR-73786487
    $invoice_number = $_GET['number'] ?? null;

    if (!$invoice_number) {
        http_response_code(400);
        echo json_encode(['error' => 'number is required']);
        exit;
    }

    $stmt = $pdo->prepare('DELETE FROM invoices WHERE invoice_number = ?');
    $stmt->execute([$invoice_number]);
    echo json_encode(['ok' => true]);

} else {
    // 不支援的 HTTP 方法
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
}
