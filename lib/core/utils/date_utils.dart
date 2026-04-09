// 日期時間處理工具類 (Date Utils Helper)
// 
// 負責共用的 DateTime 格式化處理，確保全站各處顯示的日期格式一模一樣。
// 使用了 `intl` 套件來執行 DateFormat 轉換。

import 'package:intl/intl.dart';

class DateUtilsHelper {
  /// 格式化為含有具體到分鐘的時間，例如 "2024-12-31 23:59"
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  /// 僅格式化出純日期，例如 "2024-12-31" 供介面簡潔展示
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
