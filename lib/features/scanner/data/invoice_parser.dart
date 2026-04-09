// 發票文字解析工具 (Invoice Parser)
// 
// 負責將 OCR 辨識出來的一長串非結構化純文字，
// 利用正規表達式 (Regular Expression) 萃取出發票號碼、日期、金額與店家名稱。
// ocrText
// │
// ├─【店家名稱】
// │   取第一個非空白行
// │   範例："全家便利商店"
// │
// ├─【發票號碼】Regex: [A-Za-z]{2}-?\d{8}
// │   匹配台灣標準格式 AB-12345678
// │   若無連字號自動補上
// │   範例："AB-12345678"
// │
// ├─【發票日期】Regex: (\d{4})[./-](\d{2})[./-](\d{2})
// │   支援三種分隔符 -  /  .
// │   範例："2025-03-26" / "2025/03/26"
// │
// └─【消費金額】Regex: (?:合計|總計|NT\$|\$)\s*:?\s*(\d+[,\d]*)
//     關鍵字觸發：合計 / 總計 / NT$ / $
//     自動去除千分位逗號
//     範例："合計 1,250" → 1250.0
//             ↓
//      ParsedInvoiceResult
//

import 'package:flutter/foundation.dart';

/// 暫存解析結果的資料結構
class ParsedInvoiceResult {
  final String? invoiceNumber;
  final DateTime? date;
  final String? merchantName;
  final double? amount;

  ParsedInvoiceResult({
    this.invoiceNumber,
    this.date,
    this.merchantName,
    this.amount,
  });
}

class InvoiceParser {
  /// 輸入從 OCR 抓取的原始整段文字，回傳解析出的欄位
  static ParsedInvoiceResult parse(String ocrText) {
    if (ocrText.trim().isEmpty) {
      return ParsedInvoiceResult();
    }
    
    // 將多行文字分割成 List，過濾掉空白行，方便逐行或整體解析
    final lines = ocrText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    String? merchantName;
    String? invoiceNumber;
    DateTime? invoiceDate;
    double? totalAmount;

    // 1. 解析店家名稱 (Merchant Name)
    // 預設簡單邏輯：通常發票最上方的第一行或前幾行具有最大的店名字體
    if (lines.isNotEmpty) {
      merchantName = lines.first;
    }

    // 2. 解析發票號碼 (Invoice Number)
    // 台灣發票號碼規則：2 個英文字母 + (-) + 8 個數字 (如 AB-12345678 或 AB12345678)
    final invoiceNumberRegex = RegExp(r'[A-Za-z]{2}-?\d{8}');
    final invMatch = invoiceNumberRegex.firstMatch(ocrText);
    if (invMatch != null) {
      // 全轉為大寫並先移除減號，以便統一格式化
      invoiceNumber = invMatch.group(0)?.toUpperCase().replaceAll('-', '');
      if (invoiceNumber != null && invoiceNumber.length == 10) {
        // 統一補上減號變成 AA-12345678 的標準格式
        invoiceNumber = '${invoiceNumber.substring(0,2)}-${invoiceNumber.substring(2)}';
      }
    }

    // 3. 解析發票日期 (Date)
    // 支援格式：YYYY-MM-DD, YYYY/MM/DD, YYYY.MM.DD
    final dateRegex = RegExp(r'(\d{4})[./-](\d{2})[./-](\d{2})');
    final dateMatch = dateRegex.firstMatch(ocrText);
    if (dateMatch != null) {
      try {
        final y = int.parse(dateMatch.group(1)!);
        final m = int.parse(dateMatch.group(2)!);
        final d = int.parse(dateMatch.group(3)!);
        invoiceDate = DateTime(y, m, d);
      } catch (e) {
        debugPrint("Date parse error: $e");
      }
    }

    // 4. 解析消費金額 (Amount)
    // 尋找「合計」、「總計」、「NT$」或「$」後方跟著的數字字串 (可能含有千分位逗號)
    final amountRegex = RegExp(r'(?:合計|總計|NT\$|\$)\s*:?\s*(\d+(?:,\d+)*(?:\.\d+)?)');
    final amtMatch = amountRegex.firstMatch(ocrText);
    if (amtMatch != null) {
      try {
        // 移除可能的千分位逗號再進行轉型
        String numStr = amtMatch.group(1)!.replaceAll(',', '');
        totalAmount = double.parse(numStr);
      } catch (e) {
        debugPrint("Amount parse error: $e");
      }
    }

    return ParsedInvoiceResult(
      merchantName: merchantName,
      invoiceNumber: invoiceNumber,
      date: invoiceDate,
      amount: totalAmount,
    );
  }
}
