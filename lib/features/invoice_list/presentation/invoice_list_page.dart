// 我的發票清單頁面 (Invoice List Page)
// 
// 顯示已儲存的所有發票紀錄清單，並統整總花費 (Total Expenses)。
// 支援下拉更新資料 (Pull-to-Refresh) 與刪除發票功能。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../services/api_service.dart';
import '../../scanner/domain/entities/invoice_entity.dart';
import 'invoice_list_provider.dart';
import '../widgets/invoice_card.dart';

class InvoiceListPage extends ConsumerWidget {
  const InvoiceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch：訂閱 provider，狀態一變就重建這個 Widget
    // listState 是 AsyncValue<List<InvoiceEntity>>，有三種狀態：loading / data / error
    final listState = ref.watch(invoiceListProvider);

    // ref.listen：監聽狀態變化但不重建 UI（這裡留空，用於確保 provider 不被自動卸載）
    ref.listen(invoiceListProvider, (previous, next) {});

    return Scaffold(
      appBar: CustomAppBar(
        title: '我的發票',
        actions: [
          // 對獎按鈕
          IconButton(
            tooltip: '對獎',
            icon: const Icon(Icons.emoji_events_rounded),
            onPressed: () => _checkWinners(context),
          ),
          // 重新載入按鈕
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(invoiceListProvider.notifier).loadInvoices();
            },
          )
        ],
      ),
      // listState.when() 依目前狀態分三條路：
      //   data    → 資料載入成功，invoices 是發票陣列
      //   loading → 還在等資料，顯示轉圈圈
      //   error   → 發生例外，顯示錯誤訊息
      body: listState.when(
        data: (invoices) {
          // 陣列為空 → 顯示「目前沒有發票」的提示畫面
          if (invoices.isEmpty) {
            return _buildEmptyState(context);
          }
          // 有資料 → 用 RefreshIndicator 包住，讓使用者可以下拉重新整理
          return RefreshIndicator(
            onRefresh: () async {
              // 下拉時重新向本地儲存讀取最新發票清單
              await ref.read(invoiceListProvider.notifier).loadInvoices();
            },
            child: Column(
              children: [
                // 頂部的彩色總花費卡片（所有發票金額加總）
                _buildTotalExpenseCard(context, invoices),
                // ListView.separated：有間距的清單
                // Expanded 讓清單撐滿剩餘高度，不然 Column 會報無限高度錯誤
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: invoices.length,
                    // separatorBuilder：每兩張卡片之間插入 12px 間距
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final inv = invoices[index];
                      return InvoiceCard(
                        invoice: inv,
                        // 點擊卡片 → 跳到明細頁，extra 把整個 inv 物件帶過去
                        // await 等待明細頁關閉後，重新載入清單（可能有修改）
                        onTap: () async {
                          await context.push('/invoice/${inv.id}', extra: inv);
                          ref.read(invoiceListProvider.notifier).loadInvoices();
                        },
                        // 點擊刪除 → 先彈確認對話框，確認後才真正刪除
                        onDelete: () => _confirmDelete(context, ref, inv),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('載入失敗: $err')),
      ),
      
      // 右下角浮動按鈕（FAB）：點擊跳至掃描頁
      // FloatingActionButton.extended = 有文字 + 圖示的寬版 FAB
      // 用 Container 包住是為了自訂漸層背景（FAB 本身不支援 gradient）
      // backgroundColor: Colors.transparent 讓 FAB 自己的背景透明，露出 Container 的漸層
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF10B981)], // 紫 → 綠
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4), // 向下偏移，產生立體陰影感
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.go('/scan'), // go_router 導向掃描頁
          backgroundColor: Colors.transparent,
          elevation: 0,           // 取消 FAB 預設陰影（由外層 Container 負責）
          highlightElevation: 0,  // 按下時也不抬高
          icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
          label: const Text('掃描發票', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  /// 產生於畫面完全沒有發票紀錄時的空狀態 Placeholder 介面
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 120, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            '目前沒有發票紀錄',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '點擊右下角按鈕開始掃描',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  /// 頂部彩色總花費卡片
  ///
  /// 用 fold() 把清單所有發票的金額加總，顯示在漸層卡片上
  Widget _buildTotalExpenseCard(BuildContext context, List<InvoiceEntity> invoices) {
    // fold：遍歷陣列，從初始值 0.0 開始累加每張發票的 totalAmount
    // ?? 0.0：若 totalAmount 為 null 則當作 0 處理，避免加總出錯
    final double total = invoices.fold(0.0, (sum, inv) => sum + (inv.totalAmount ?? 0.0));
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '總花費 (Total Expenses)',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${total.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  /// 呼叫後端 /check.php 進行對獎，並以 AlertDialog 顯示結果
  Future<void> _checkWinners(BuildContext context) async {
    // ⚠️ 重要：在 await 之前先把 navigator 存起來
    // 原因：await 等待期間使用者可能切換頁面，導致 context 失效（unmounted）
    // 儲存後即使 context 失效，仍可用 navigator 操作對話框
    // rootNavigator: true → 使用最頂層的 Navigator，避免被巢狀路由攔截
    final navigator = Navigator.of(context, rootNavigator: true);

    // 先顯示 loading 轉圈圈，barrierDismissible: false 讓使用者無法點空白處關掉
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 呼叫後端對獎 API（非同步等待網路回應）
      final result = await ApiService.checkWinners();

      // await Future.delayed(Duration.zero)：讓出一個畫面幀（frame）
      // 原因：showDialog 的動畫還在跑時若立刻再 pop，會觸發 Flutter 的 _debugLocked 斷言錯誤
      await Future.delayed(Duration.zero);
      if (navigator.canPop()) navigator.pop(); // 關掉 loading 轉圈圈

      // context.mounted：確認 Widget 還在畫面上，若已被移除則直接結束
      if (!context.mounted) return;

      // 從後端回傳的 Map 取出三個欄位，加上 ?? 防止 null 造成錯誤
      final int count = (result['count'] as int?) ?? 0;           // 中獎張數
      final int total = (result['total_prize'] as int?) ?? 0;     // 總獎金
      final List winners = (result['winners'] as List?) ?? [];    // 中獎明細陣列

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                count > 0 ? Icons.emoji_events_rounded : Icons.sentiment_neutral_rounded,
                color: count > 0 ? Colors.amber : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(count > 0 ? '恭喜中獎!' : '本次未中獎'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('中獎張數:$count 張'),
                Text('總獎金:\$$total'),
                if (winners.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('明細:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...winners.map((w) {
                    final m = Map<String, dynamic>.from(w as Map);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '• ${m['invoice_number']}  ${m['prize_type']}  \$${m['prize_amount']}',
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('關閉'),
            ),
          ],
        ),
      );
    } catch (e) {
      // 網路斷線、後端未啟動、JSON 解析失敗等例外都會到這裡
      await Future.delayed(Duration.zero);
      if (navigator.canPop()) navigator.pop(); // 關掉 loading 轉圈圈
      if (!context.mounted) return;
      // 顯示錯誤訊息對話框，讓使用者知道出了什麼問題
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('對獎失敗'),
          content: Text('無法連線到後端伺服器:\n$e'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('確定')),
          ],
        ),
      );
    }
  }

  /// 刪除前的二次確認對話框
  ///
  /// 防止使用者誤觸刪除，確認後才真正執行刪除動作
  void _confirmDelete(BuildContext context, WidgetRef ref, InvoiceEntity inv) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('確認刪除', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('要刪除這張發票紀錄嗎？此動作無法復原。'),
        actions: [
          // 取消：直接關掉對話框，不做任何事
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          // 確認刪除：
          //   inv.id           → 刪除手機本地端的資料（UUID 格式）
          //   inv.invoiceNumber → 刪除後端 MySQL 的資料（發票號碼格式，如 WR-73786487）
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50),
            onPressed: () {
              ref.read(invoiceListProvider.notifier).deleteInvoice(inv.id, invoiceNumber: inv.invoiceNumber);
              Navigator.pop(c); // 刪除後關掉對話框
            },
            child: Text('刪除', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
