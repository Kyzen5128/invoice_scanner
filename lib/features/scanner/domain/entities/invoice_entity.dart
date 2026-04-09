// 發票資料模型實體 (Invoice Entity)
// 
// 這是整支 App 最核心的資料模型，代表一張發票的完整結構。
// 支援 JSON 序列化與反序列化，以便透過 LocalStorage 儲存至本地機器。
// 同時利用 copyWith 方法支援不可變 (Immutable) 的狀態更新。

class InvoiceEntity {
  /// 每筆發票的唯一識別碼 (通常使用 UUID 產生)
  final String id;
  
  /// 發票被掃描或匯入系統的時間點
  final DateTime scannedAt;
  
  /// 與此發票相關聯的圖片本機路徑 (方便後續在明細頁或清單預覽顯示)
  final String imageLocalPath;
  
  /// 辨識出的發票號碼 (可能為 null 如果 OCR 失敗)
  final String? invoiceNumber;
  
  /// 辨識出的發票日期 (可能為 null)
  final DateTime? date;
  
  /// 辨識出的店家或營業人名稱 (可能為 null)
  final String? merchantName;
  
  /// 總消費金額 (可能為 null)
  final double? totalAmount;
  
  /// OCR 引擎所吐出的所有原始文字 (供開發除錯及使用者核對用)
  final String rawOcrText;
  
  /// 用戶是否有在明細頁面中手動編輯過這張發票的紀錄
  final bool isManuallyEdited;

  InvoiceEntity({
    required this.id,
    required this.scannedAt,
    required this.imageLocalPath,
    this.invoiceNumber,
    this.date,
    this.merchantName,
    this.totalAmount,
    required this.rawOcrText,
    this.isManuallyEdited = false,
  });

  /// 從 JSON 格式字典反序列化為 InvoiceEntity 實體
  factory InvoiceEntity.fromJson(Map<String, dynamic> json) {
    return InvoiceEntity(
      id: json['id'] as String,
      scannedAt: DateTime.parse(json['scannedAt'] as String),
      imageLocalPath: json['imageLocalPath'] as String,
      invoiceNumber: json['invoiceNumber'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      merchantName: json['merchantName'] as String?,
      
      // 確保轉型安全，將 num 轉為 double
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      rawOcrText: json['rawOcrText'] as String,
      isManuallyEdited: json['isManuallyEdited'] as bool? ?? false,
    );
  }

  /// 將 InvoiceEntity 實體序列化為 JSON 變數字典，以便存入本地資料庫
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scannedAt': scannedAt.toIso8601String(),
      'imageLocalPath': imageLocalPath,
      'invoiceNumber': invoiceNumber,
      'date': date?.toIso8601String(),
      'merchantName': merchantName,
      'totalAmount': totalAmount,
      'rawOcrText': rawOcrText,
      'isManuallyEdited': isManuallyEdited,
    };
  }

  /// 實作拷貝方法 (Immutable Pattern)，用於在產生新狀態時修改特定欄位
  InvoiceEntity copyWith({
    String? id,
    DateTime? scannedAt,
    String? imageLocalPath,
    String? invoiceNumber,
    DateTime? date,
    String? merchantName,
    double? totalAmount,
    String? rawOcrText,
    bool? isManuallyEdited,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      scannedAt: scannedAt ?? this.scannedAt,
      imageLocalPath: imageLocalPath ?? this.imageLocalPath,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      isManuallyEdited: isManuallyEdited ?? this.isManuallyEdited,
    );
  }
}
