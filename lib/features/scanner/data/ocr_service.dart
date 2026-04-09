// 光學字元辨識服務 (OCR Service)
// 
// 負責呼叫 Google ML Kit 進行單機端的文字辨識。
// 此實作支援本地端辨識，不需將圖片上傳伺服器即可完成。

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  // 初始化 TextRecognizer 並指定使用繁體中文等亞洲語系的腳本
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);

  /// 輸入圖片路徑，回傳圖片中所有辨識出的純文字內容字串
  /// [imagePath] 儲存在手機本地端的相片絕對路徑
  Future<String> processImage(String imagePath) async {
    try {
      // 1. 建立 ML Kit 需要的影像格式
      final inputImage = InputImage.fromFilePath(imagePath);
      // 2. 觸發影像辨識引擎進行處理
      final recognizedText = await _textRecognizer.processImage(inputImage);
      // 3. 回傳文字結果
      return recognizedText.text;
    } catch (e) {
      // 若中途發生底層錯誤，僅在控制台印出並回傳空字串，防止 App 崩潰
      debugPrint("OCR Error: $e");
      return "";
    }
  }

  /// 釋放辨識引擎資源，避免記憶體洩漏 (Memory leak)
  void dispose() {
    _textRecognizer.close();
  }
}
