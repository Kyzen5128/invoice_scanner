// 發票明細編輯的狀態管理 (Invoice Detail Provider)
// 
// 負責單筆發票的讀寫、編輯與驗證狀態。
// 在用戶更動欄位時更新記憶體狀態，並在點擊儲存時複寫至本地儲存方案中。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../scanner/domain/entities/invoice_entity.dart';
import '../../../shared/services/local_storage_service.dart';
import '../../../services/api_service.dart';

// 定義一個簡單的 Provider 來取用 LocalStorageService 服務
final localStorageServiceProvider = Provider((ref) => LocalStorageService());

/// 使用 .family 建構子，因為每一個明細頁面都有各自對應的 InvoiceEntity 初始狀態
final invoiceDetailProvider = StateNotifierProvider.family<InvoiceDetailNotifier, InvoiceEntity, InvoiceEntity>((ref, initialInvoice) {
  final storage = ref.watch(localStorageServiceProvider);
  return InvoiceDetailNotifier(initialInvoice, storage);
});

class InvoiceDetailNotifier extends StateNotifier<InvoiceEntity> {
  final LocalStorageService _storage;

  InvoiceDetailNotifier(super.initialInvoice, this._storage);

  /// 當使用者在明細頁面的任何文字框編輯時，呼叫此函式更新單筆狀態 (Immutable)
  void updateField({
    String? invoiceNumber,
    DateTime? date,
    String? merchantName,
    double? totalAmount,
  }) {
    state = state.copyWith(
      invoiceNumber: invoiceNumber,
      date: date,
      merchantName: merchantName,
      totalAmount: totalAmount,
      isManuallyEdited: true, // 標記為已被手動編輯過
    );
  }

  /// 將當前最新的修正狀態寫入檔案系統與本地資料庫
  Future<void> save() async {
    // 確保持久保存發票被拍下時的圖片，將其由暫存區(tmp)複製至 App 文件目錄中
    final savedImagePath = await _storage.copyImageToAppDirectory(state.imageLocalPath, state.id);
    
    // 更新 Entity 使其指向永久儲存路徑
    final entityToSave = state.copyWith(imageLocalPath: savedImagePath);
    
    // 呼叫底層儲存服務覆寫或新增該筆發票
    await _storage.saveInvoice(entityToSave);

    // 同步推送到後端資料庫 (Plan B: 本地 + 後端雙寫)
    // 失敗不影響本地儲存,只記錄錯誤,這樣離線也能用
    try {
      final number = entityToSave.invoiceNumber;
      final date = entityToSave.date ?? entityToSave.scannedAt;
      if (number != null && number.isNotEmpty) {
        await ApiService.addInvoice(
          invoiceNumber: number,
          period: ApiService.periodFromDate(date),
          amount: (entityToSave.totalAmount ?? 0).round(),
          invoiceDate: date.toIso8601String().substring(0, 10),
          imagePath: entityToSave.imageLocalPath,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('[InvoiceDetail] 後端同步失敗 (本地已儲存): $e');
    }
  }
}
