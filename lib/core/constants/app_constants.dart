// 全域常數設定 (App Constants)
// 
// 集中管理應用程式中常用的靜態字串或識別名稱，避免因拼字錯誤(Typo)產生的 Bug。
// 包含目錄名稱與檔案名稱設定。

class AppConstants {
  /// 全域 App 顯示名稱字串
  static const String appName = '發票掃描器';
  
  // -- 本機儲存 (Storage) 的固定檔名與目錄名 --
  
  /// 發票紀錄在 App Documents 之中的預設資料夾名稱
  static const String invoiceDirectoryName = 'invoices';
  /// 發票 JSON 索引列表的固定檔案名稱
  static const String invoiceJsonFileName = 'invoices.json';
}
