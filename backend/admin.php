<?php
// 中獎號碼管理頁面
// 開啟方式：瀏覽器前往 http://localhost/invoice_scanner/admin.php

require_once 'db.php';

$message = '';
$error   = '';

// ─── 新增中獎號碼（表單送出）────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'add') {
    $period       = trim($_POST['period']       ?? '');
    $prize_type   = trim($_POST['prize_type']   ?? '');
    $number       = trim($_POST['number']       ?? '');
    $prize_amount = trim($_POST['prize_amount'] ?? '');

    if (!$period || !$prize_type || !$number || !$prize_amount) {
        $error = '所有欄位都必須填寫';
    } else {
        $stmt = $pdo->prepare(
            'INSERT INTO winning_numbers (period, prize_type, number, prize_amount) VALUES (?, ?, ?, ?)'
        );
        $stmt->execute([$period, $prize_type, $number, (int)$prize_amount]);
        $message = "✅ 已新增：$period 期 / $prize_type / $number / \$$prize_amount";
    }
}

// ─── 刪除中獎號碼 ────────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'delete') {
    $id = (int)($_POST['id'] ?? 0);
    if ($id > 0) {
        $pdo->prepare('DELETE FROM winning_numbers WHERE id = ?')->execute([$id]);
        $message = '🗑️ 已刪除';
    }
}

// ─── 讀取現有資料 ────────────────────────────────────────────────
$rows = $pdo->query('SELECT * FROM winning_numbers ORDER BY period DESC, prize_amount DESC')->fetchAll();
?>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <title>中獎號碼管理</title>
  <style>
    body { font-family: sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; }
    h2   { border-bottom: 2px solid #4F46E5; padding-bottom: 8px; color: #4F46E5; }
    .msg { padding: 10px 16px; border-radius: 6px; margin-bottom: 16px; }
    .msg.success { background: #d1fae5; color: #065f46; }
    .msg.error   { background: #fee2e2; color: #991b1b; }
    form.add-form { background: #f9fafb; padding: 20px; border-radius: 10px; margin-bottom: 32px; }
    label  { display: block; margin-bottom: 12px; font-size: 14px; }
    input  { display: block; margin-top: 4px; padding: 8px; border: 1px solid #d1d5db;
             border-radius: 6px; width: 100%; box-sizing: border-box; font-size: 15px; }
    button.submit { background: #4F46E5; color: #fff; border: none; padding: 10px 24px;
                    border-radius: 6px; cursor: pointer; font-size: 15px; }
    button.submit:hover { background: #4338ca; }
    table  { width: 100%; border-collapse: collapse; }
    th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid #e5e7eb; }
    th     { background: #f3f4f6; font-size: 13px; color: #374151; }
    button.del { background: #fee2e2; color: #991b1b; border: none; padding: 4px 12px;
                 border-radius: 4px; cursor: pointer; }
    button.del:hover { background: #fecaca; }
  </style>
</head>
<body>

<h2>中獎號碼管理</h2>

<?php if ($message): ?>
  <div class="msg success"><?= htmlspecialchars($message) ?></div>
<?php endif; ?>
<?php if ($error): ?>
  <div class="msg error"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<!-- 新增表單 -->
<form class="add-form" method="POST">
  <input type="hidden" name="action" value="add">

  <label>
    期別（例：11502）
    <input name="period" placeholder="11502" required>
  </label>
  <label>
    獎別（例：特別獎、頭獎、六獎）
    <input name="prize_type" placeholder="特別獎" required>
  </label>
  <label>
    中獎號碼（例：WR-73786487）
    <input name="number" placeholder="WR-73786487" required>
  </label>
  <label>
    獎金金額（例：2000000）
    <input name="prize_amount" type="number" placeholder="2000000" required>
  </label>

  <button class="submit" type="submit">新增中獎號碼</button>
</form>

<!-- 現有資料列表 -->
<h2>現有中獎號碼（共 <?= count($rows) ?> 筆）</h2>

<?php if (empty($rows)): ?>
  <p style="color:#6b7280">尚無資料</p>
<?php else: ?>
  <table>
    <tr>
      <th>期別</th>
      <th>獎別</th>
      <th>號碼</th>
      <th>獎金</th>
      <th>操作</th>
    </tr>
    <?php foreach ($rows as $row): ?>
    <tr>
      <td><?= htmlspecialchars($row['period']) ?></td>
      <td><?= htmlspecialchars($row['prize_type']) ?></td>
      <td><?= htmlspecialchars($row['number']) ?></td>
      <td>$<?= number_format($row['prize_amount']) ?></td>
      <td>
        <form method="POST" style="display:inline"
              onsubmit="return confirm('確定刪除這筆中獎號碼？')">
          <input type="hidden" name="action" value="delete">
          <input type="hidden" name="id" value="<?= $row['id'] ?>">
          <button class="del" type="submit">刪除</button>
        </form>
      </td>
    </tr>
    <?php endforeach; ?>
  </table>
<?php endif; ?>

</body>
</html>
