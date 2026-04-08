// Invoice Scanner Backend API
// 啟動: node server.js  (預設 port 3000)

const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');

const app = express();
app.use(cors());
app.use(express.json());

// === MySQL 連線設定 (XAMPP MariaDB, root 無密碼) ===
const db = mysql.createPool({
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: '',
  database: 'invoice_db',
  waitForConnections: true,
  connectionLimit: 10,
});

// === 健康檢查 ===
app.get('/', (req, res) => {
  res.json({ ok: true, message: 'Invoice API is running' });
});

// === 新增發票 ===
// POST /invoices  body: { invoice_number, period, amount, invoice_date, image_path }
app.post('/invoices', async (req, res) => {
  try {
    console.log('\n📥 [POST /invoices] 收到:', JSON.stringify(req.body));
    const { invoice_number, period, amount, invoice_date, image_path } = req.body;
    if (!invoice_number || !period) {
      return res.status(400).json({ error: 'invoice_number and period are required' });
    }

    // 同一張發票可能被使用者編輯後重新儲存，所以要先確認是否已存在
    // 用 (invoice_number + period) 當作唯一識別，因為同號碼不同期是不同發票
    const [existing] = await db.query(
      'SELECT id FROM invoices WHERE invoice_number = ? AND period = ?',
      [invoice_number, period]
    );

    let resultId;
    if (existing.length > 0) {
      // 已有這張發票 → 更新內容（例如使用者修正了金額或日期）
      await db.query(
        'UPDATE invoices SET amount=?, invoice_date=?, image_path=? WHERE invoice_number=? AND period=?',
        [amount || 0, invoice_date || null, image_path || null, invoice_number, period]
      );
      resultId = existing[0].id;
      console.log('   ✅ 已更新, id =', resultId);
    } else {
      // 第一次儲存這張發票 → 新增一筆
      const [result] = await db.query(
        'INSERT INTO invoices (invoice_number, period, amount, invoice_date, image_path) VALUES (?,?,?,?,?)',
        [invoice_number, period, amount || 0, invoice_date || null, image_path || null]
      );
      resultId = result.insertId;
      console.log('   ✅ 已新增, insertId =', resultId);
    }

    res.json({ ok: true, id: resultId });
  } catch (e) {
    console.error('   ❌ POST /invoices 失敗:', e.message);
    res.status(500).json({ error: e.message });
  }
});

// === 查詢全部發票 ===
app.get('/invoices', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM invoices ORDER BY created_at DESC');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// === 刪除發票 (依發票號碼) ===
// Flutter 前端用發票號碼來刪除，因為前端存的是 UUID，後端存的是 MySQL 整數 id，兩者對不上
// ⚠️ 這個路由必須寫在 /invoices/:id 之前
//    原因：Express 從上到下依序比對路由
//    如果 /:id 寫在前面，"number" 這個字串會被當成 :id 的值，導致找不到資料
app.delete('/invoices/number/:invoiceNumber', async (req, res) => {
  try {
    // 發票號碼含有 "-" 符號（如 WR-73786487），URL 傳送時需要解碼
    const number = decodeURIComponent(req.params.invoiceNumber);
    console.log('\n🗑️  [DELETE /invoices/number/' + number + '] 刪除發票');
    const [result] = await db.query('DELETE FROM invoices WHERE invoice_number = ?', [number]);
    console.log('   ✅ 已刪除, affectedRows =', result.affectedRows);
    res.json({ ok: true, affectedRows: result.affectedRows });
  } catch (e) {
    console.error('   ❌ DELETE /invoices/number 失敗:', e.message);
    res.status(500).json({ error: e.message });
  }
});

// === 刪除發票 (依 MySQL id) ===
app.delete('/invoices/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM invoices WHERE id = ?', [req.params.id]);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// === 查詢某期中獎號碼 ===
app.get('/winning/:period', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM winning_numbers WHERE period = ?',
      [req.params.period]
    );
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// === 查詢全部中獎號碼 ===
app.get('/winning', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM winning_numbers ORDER BY period DESC');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// === 對獎: 比對使用者所有發票是否中獎 ===
// GET /check  回傳所有中獎的發票及獎金
app.get('/check', async (req, res) => {
  try {
    console.log('\n🎰 [GET /check] 開始對獎...');
    const [rows] = await db.query(`
      SELECT i.id, i.invoice_number, i.period, w.prize_type, w.prize_amount
      FROM invoices i
      JOIN winning_numbers w
        ON i.period = w.period
       AND i.invoice_number = w.number
      ORDER BY w.prize_amount DESC
    `);
    const total = rows.reduce((s, r) => s + r.prize_amount, 0);
    const payload = { count: rows.length, total_prize: total, winners: rows };
    console.log('   📤 回應:', JSON.stringify(payload));
    res.json(payload);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// === 啟動 ===
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`✅ Invoice API running at http://localhost:${PORT}`);
});
