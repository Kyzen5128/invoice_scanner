// 發票明細與編輯頁面 (Invoice Detail Page)
// 
// 提供單張發票的詳細資訊展示，包含影像預覽與 OCR 原始擷取文字。
// 開放讓使用者可以針對辨識錯誤的欄位進行手動修正 (號碼、日期、金額、店家)，
// 並支援點擊右上角勾選按鈕將修改儲存進本地資料庫。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../scanner/domain/entities/invoice_entity.dart';
import 'invoice_detail_provider.dart';

/// ConsumerStatefulWidget 用於需管理本身輸入框狀態，並結合 Riverpod
class InvoiceDetailPage extends ConsumerStatefulWidget {
  /// 傳進來的初始發票實體 (可能剛掃描完，或從清單點進來)
  final InvoiceEntity invoice;
  /// 是否為全新掃描的發票 (控制標題顯示「確認發票內容」或「發票明細」)
  final bool isNew;

  const InvoiceDetailPage({super.key, required this.invoice, this.isNew = false});

  @override
  ConsumerState<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends ConsumerState<InvoiceDetailPage> {
  // 分別為發票的四個欄位建立文字輸入控制器
  late TextEditingController _numberController;
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    // 將傳入實體的資料賦值給控制器，使其顯示在對應的欄位上
    _numberController = TextEditingController(text: widget.invoice.invoiceNumber ?? '');
    _merchantController = TextEditingController(text: widget.invoice.merchantName ?? '');
    _amountController = TextEditingController(text: widget.invoice.totalAmount?.toString() ?? '');
    _dateController = TextEditingController(
      // 將 DateTime 格式化為字串
      text: widget.invoice.date != null ? DateUtilsHelper.formatDate(widget.invoice.date!) : '',
    );
  }

  @override
  void dispose() {
    // 釋放記憶體
    _numberController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 建立並監聽該特定發票實體的 provider
    final provider = invoiceDetailProvider(widget.invoice);
    final state = ref.watch(provider);

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.isNew ? '確認發票內容' : '發票明細',
        actions: [
          // 儲存修改的按鈕 (右上角勾號)
          IconButton(
            icon: const Icon(Icons.check_circle_rounded),
            tooltip: '儲存',
            onPressed: () async {
              // 1. 嘗試將字串安全轉型回 double
              double? amount;
              if (_amountController.text.isNotEmpty) {
                 amount = double.tryParse(_amountController.text);
              }

              // 2. 嘗試將字串 YYYY-MM-DD 安全轉換為 DateTime
              DateTime? date;
              if (_dateController.text.isNotEmpty) {
                 try {
                   final parts = _dateController.text.split('-');
                   if (parts.length == 3) {
                     date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                   }
                 } catch (_) {}
              }

              // 3. 呼叫 notifier 批次更新欄位
              ref.read(provider.notifier).updateField(
                invoiceNumber: _numberController.text,
                merchantName: _merchantController.text,
                totalAmount: amount,
                date: date,
              );

              // 4. 先抓住 navigator 跟 router (避免 await 後 context 失效或 navigator 鎖定)
              final navigator = Navigator.of(context, rootNavigator: true);
              final router = GoRouter.of(context);

              // 5. 顯示全螢幕半透明等待彈窗
              showDialog(
                context: context,
                barrierDismissible: false,
                useRootNavigator: true,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );

              // 6. 等待寫入本地儲存庫 + 推送後端
              try {
                await ref.read(provider.notifier).save();
              } catch (e) {
                await Future.delayed(Duration.zero);
                if (navigator.canPop()) navigator.pop();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('儲存失敗: $e')),
                );
                return;
              }

              // 7. 等下一個 frame 確保 dialog 完全 push 完才能 pop,避免 _debugLocked
              await Future.delayed(Duration.zero);

              // 8. 關閉等待彈窗,並切換回發票清單頁
              if (navigator.canPop()) navigator.pop();
              router.go('/invoices');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 如果此發票附有在本機的照片檔案路徑，顯示圖片供對照
            if (state.imageLocalPath.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxHeight: 350),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                clipBehavior: Clip.antiAlias, // 讓圖片可以完整切齊圓角
                child: Image.file(
                  File(state.imageLocalPath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                ),
              ),
            
            // 下半部的主要表單區塊
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 標題列
                  Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('檢視與修正欄位', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 發票號碼輸入框
                  TextField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                      labelText: '發票號碼',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 日期輸入框
                  TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: '發票日期 (YYYY-MM-DD)',
                      prefixIcon: Icon(Icons.date_range_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 店家名稱輸入框
                  TextField(
                    controller: _merchantController,
                    decoration: const InputDecoration(
                      labelText: '店家名稱',
                      prefixIcon: Icon(Icons.storefront_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 消費總額輸入框 (限定數字鍵盤)
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '消費金額',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                  ),
                  // 底端附上 OCR 最原始擷取的文字，讓使用者若某些欄位辨識錯誤，可從原始文字中尋找解答
                  const SizedBox(height: 32),
                  const Text('原始 OCR 辨識文字', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50], // 非常淺的灰階底色
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!)
                    ),
                    child: Text(
                      state.rawOcrText.isEmpty ? '無文字' : state.rawOcrText,
                      style: const TextStyle(height: 1.5, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
