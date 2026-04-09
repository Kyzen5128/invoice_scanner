// Flutter 端呼叫後端 API 的服務
//
// 注意: baseUrl 依執行環境調整
//   - Android 模擬器:  http://10.0.2.2/invoice_scanner
//   - iOS 模擬器/桌面: http://localhost/invoice_scanner
//   - 實機:           http://你電腦的區域網路 IP/invoice_scanner

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Android 模擬器：10.0.2.2 對應到電腦的 localhost（Apache 預設 port 80，不需要寫 port）
  static const String baseUrl = 'http://10.0.2.2/invoice_scanner';

  /// 從發票日期推算統一發票期別代碼
  /// 例: 2024-04-15 → 民國113年3-4月 → "11304"
  ///     2024-05-01 → 民國113年5-6月 → "11306"
  static String periodFromDate(DateTime date) {
    final roc = date.year - 1911;
    final evenMonth = date.month % 2 == 0 ? date.month : date.month + 1;
    return '$roc${evenMonth.toString().padLeft(2, '0')}';
  }

  // === 新增發票 ===
  static Future<int?> addInvoice({
    required String invoiceNumber,
    required String period,
    int amount = 0,
    String? invoiceDate,
    String? imagePath,
  }) async {
    final body = {
      'invoice_number': invoiceNumber,
      'period': period,
      'amount': amount,
      'invoice_date': invoiceDate,
      'image_path': imagePath,
    };
    debugPrint('📤 [API] POST /invoices  送出: ${jsonEncode(body)}');
    final res = await http.post(
      Uri.parse('$baseUrl/invoices.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    debugPrint('📥 [API] POST /invoices  收到 ${res.statusCode}: ${res.body}');
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['id'] as int?;
    }
    throw Exception('addInvoice failed: ${res.statusCode} ${res.body}');
  }

  // === 取得全部發票 ===
  // 回傳所有已存入後端的發票清單，依 created_at 由新到舊排序
  static Future<List<Map<String, dynamic>>> fetchInvoices() async {
    final res = await http.get(Uri.parse('$baseUrl/invoices.php'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    throw Exception('fetchInvoices failed: ${res.statusCode}');
  }

  // === 刪除發票 (依發票號碼) ===
  // 為什麼不用 MySQL id？
  //   → Flutter 本地端用 UUID 當 id，後端 MySQL 用整數 AUTO_INCREMENT 當 id
  //   → 兩個 id 格式不同，無法對應
  //   → 所以改用「發票號碼」來刪除，兩端都認識這個欄位
  // Uri.encodeComponent：將發票號碼中的 "-" 等特殊字元轉成 URL 安全格式再送出
  static Future<void> deleteInvoiceByNumber(String invoiceNumber) async {
    final encoded = Uri.encodeComponent(invoiceNumber);
    debugPrint('📤 [API] DELETE /invoices.php?number=$encoded');
    final res = await http.delete(Uri.parse('$baseUrl/invoices.php?number=$encoded'));
    debugPrint('📥 [API] DELETE /invoices.php  收到 ${res.statusCode}: ${res.body}');
    if (res.statusCode != 200) {
      throw Exception('deleteInvoiceByNumber failed: ${res.statusCode}');
    }
  }

  // === 取得某期中獎號碼 ===
  // period 格式範例: "11304"（民國113年3-4月）
  // 回傳該期所有中獎號碼，包含 prize_type（獎別）和 prize_amount（獎金）
  static Future<List<Map<String, dynamic>>> fetchWinningNumbers(String period) async {
    final res = await http.get(Uri.parse('$baseUrl/winning.php?period=$period'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    throw Exception('fetchWinningNumbers failed: ${res.statusCode}');
  }

  // === 對獎: 取得所有中獎發票及總獎金 ===
  static Future<Map<String, dynamic>> checkWinners() async {
    debugPrint('📤 [API] GET /check  發起對獎請求');
    final res = await http.get(Uri.parse('$baseUrl/check.php'));
    debugPrint('📥 [API] GET /check  收到 ${res.statusCode}: ${res.body}');
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('checkWinners failed: ${res.statusCode}');
  }
}
