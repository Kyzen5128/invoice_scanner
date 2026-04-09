// 掃描狀態管理 (Scanner State Provider)
// 
// 負責處理發票掃描的核心業務邏輯。
// 包含呼叫 OcrService 進行文字辨識，將文字解析出發票欄位，以及處理讀取相簿的邏輯。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../data/ocr_service.dart';
import '../data/invoice_parser.dart';
import '../domain/entities/invoice_entity.dart';

/// 全域提供的 scannerProvider 狀態管理者
final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  // 將 OcrService 注入至 Notifier 以利解耦
  return ScannerNotifier(OcrService());
});

/// 掃描頁面的狀態封裝類別
class ScannerState {
  final bool isLoading;       // 目前是否正在辨識或處理圖檔
  final String? error;        // 若發生錯誤時的錯誤訊息
  final InvoiceEntity? result; // 最終辨識成功產出的發票資料實體

  ScannerState({this.isLoading = false, this.error, this.result});

  /// 產生新狀態的輔助函式 (Immutable pattern)
  ScannerState copyWith({bool? isLoading, String? error, InvoiceEntity? result}) {
    return ScannerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
    );
  }
}

/// 掃描狀態變更的控制器 (Notifier)
class ScannerNotifier extends StateNotifier<ScannerState> {
  final OcrService _ocrService;
  final ImagePicker _picker = ImagePicker();

  ScannerNotifier(this._ocrService) : super(ScannerState());

  /// 觸發從相簿中挑選照片來進行發票辦識
  Future<void> scanFromGallery() async {
    try {
      // 開啟系統相簿選擇器
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      
      // 若使用者有選取照片，則進入相同的圖片辨識流程
      if (image != null) {
        await processCapturedImage(image.path);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '讀取相簿發生錯誤: $e');
    }
  }

  /// 處理剛拍攝好或選好的圖片檔案，進行 OCR 與資料萃取
  Future<void> processCapturedImage(String imagePath) async {
    try {
      // 1. 設定狀態為正在載入中 (顯示 Loading 畫面)
      state = state.copyWith(isLoading: true, error: null);

      // 2. 呼叫 OCR 服務對圖片進行文字辨識
      final rawText = await _ocrService.processImage(imagePath);
      
      // 若無文字則直接中斷並回報錯誤
      if (rawText.isEmpty) {
        state = state.copyWith(isLoading: false, error: '無法辨識文字，請重試');
        return;
      }

      // 3. 將辨識出來的原始文字送交 Parser (正規表達式) 萃取欄位
      final parsedData = InvoiceParser.parse(rawText);

      // 4. 建立暫時的 InvoiceEntity 實體 (供明細頁檢視修正使用)
      final entity = InvoiceEntity(
        id: const Uuid().v4(),          // 賦予隨機唯一的 ID
        scannedAt: DateTime.now(),
        imageLocalPath: imagePath,
        invoiceNumber: parsedData.invoiceNumber,
        date: parsedData.date,
        merchantName: parsedData.merchantName,
        totalAmount: parsedData.amount,
        rawOcrText: rawText,
      );

      // 5. 更新狀態，將辨識結果送到畫面上 (觸發導覽至明細頁)
      state = state.copyWith(isLoading: false, result: entity);

    } catch (e) {
      state = state.copyWith(isLoading: false, error: '掃描發生錯誤: $e');
    }
  }

  /// 清除掃描結果，重置回初始狀態
  void reset() {
    state = ScannerState();
  }
}
