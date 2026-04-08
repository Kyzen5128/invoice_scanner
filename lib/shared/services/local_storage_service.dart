/// 本地檔案儲存服務 (Local Storage Service)
/// 
/// 負責將發票資料 (JSON) 與實體照片檔案安全地永久儲存在設備本地端。
/// 使用了 `path_provider` 來取得應用程式的專屬沙盒可讀寫目錄 (Documents Directory)。

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/scanner/domain/entities/invoice_entity.dart';
import '../../core/constants/app_constants.dart';

class LocalStorageService {
  /// 取得統一用來存放 invoices.json 的 File 實體
  Future<File> _getInvoicesFile() async {
    // 取得 App 專屬的 Documents 路徑 (只有 App 自身能存取)
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${AppConstants.invoiceDirectoryName}';
    
    // 若目錄不存在則先建立該目錄
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    // 回傳 json 檔案路徑
    return File('$path/${AppConstants.invoiceJsonFileName}');
  }

  /// 讀取所有儲存的發票紀錄並反序列化為 InvoiceEntity 陣列
  Future<List<InvoiceEntity>> readInvoices() async {
    try {
      final file = await _getInvoicesFile();
      // 如果完全沒有儲存過 (第一次開啟)，回傳空陣列
      if (!await file.exists()) {
        return [];
      }
      
      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) return [];
      
      // 解析 JSON 字串轉成動態 List，再 mapping 成強型別的 InvoiceEntity
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => InvoiceEntity.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error reading invoices: $e');
      return []; // 若發生損毀或其他錯誤，為防崩潰直接回傳空陣列
    }
  }

  /// 新增或覆寫更新特定發票紀錄
  Future<void> saveInvoice(InvoiceEntity newInvoice) async {
    // 1. 先讀取舊的所有資料
    final invoices = await readInvoices();
    
    // 2. 透過 ID 檢查是否為已存在的舊紀錄
    final index = invoices.indexWhere((inv) => inv.id == newInvoice.id);
    if (index >= 0) {
      // 找到舊紀錄 => 取代原本的
      invoices[index] = newInvoice;
    } else {
      // 找不到 => 新加入陣列
      invoices.add(newInvoice);
    }
    
    // 3. 重新序列化並把整個 JSON 字串覆寫回儲存檔裡
    final file = await _getInvoicesFile();
    final jsonString = jsonEncode(invoices.map((e) => e.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  /// 根據指定的 ID 將發票從本地儲存中永久刪除
  Future<void> deleteInvoice(String id) async {
    final invoices = await readInvoices();
    
    // 移除陣列中所有符合該 ID 的元素
    invoices.removeWhere((element) => element.id == id);
    
    // 將刪除後的陣列重新序列化定寫入檔案
    final file = await _getInvoicesFile();
    final jsonString = jsonEncode(invoices.map((e) => e.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  /// 複製圖片：將來自相機快照或相簿選擇的暫存圖檔，合法持久保存至 App 目錄下
  Future<String> copyImageToAppDirectory(String sourcePath, String id) async {
    // 路徑為空時直接回傳空字串，不做任何動作
    if (sourcePath.isEmpty) return sourcePath;

    final directory = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${directory.path}/${AppConstants.invoiceDirectoryName}/images');

    // 確保 images 資料夾存在
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }

    // 保留原本檔案的副檔名 (如 .jpg, .png)
    final ext = sourcePath.split('.').last;

    // 構建有規律性、無碰撞可能性的新檔名 (使用該筆發票紀錄的 UUID)
    final targetPath = '${imgDir.path}/img_$id.$ext';

    // 若來源與目標相同 (已複製過)，直接回傳不重複拷貝
    if (sourcePath == targetPath) return targetPath;

    // 來源檔案不存在時直接回傳原路徑，避免崩潰
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return sourcePath;

    // 實際執行 I/O 拷貝動作
    await sourceFile.copy(targetPath);

    // 回傳新的永久保存路徑給呼叫端
    return targetPath;
  }
}
