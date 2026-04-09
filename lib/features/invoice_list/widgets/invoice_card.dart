// 發票清單的單項卡片元件 (Invoice Card Widget)
// 
// 負責渲染 `我的發票` 列表中的每一筆紀錄。
// 支援點擊整個卡片跳轉，並具備垃圾桶圖示供觸發單筆刪除的事件回調。

import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart';
import '../../scanner/domain/entities/invoice_entity.dart';

class InvoiceCard extends StatelessWidget {
  /// 傳入的發票資料實體
  final InvoiceEntity invoice;
  /// 使用者點擊卡片主體時的回調
  final VoidCallback onTap;
  /// 使用者點擊右側垃圾桶時的回調
  final VoidCallback onDelete;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 整個外層容器提供微弱的陰影與白底圓角
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // 輕微的陰影讓卡片浮起
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias, // 切齊水波紋特效的邊緣
      child: Material(
        color: Colors.transparent, // 讓底下的白底透上來，同時保留 Material 點擊特效
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 左邊的彩色 Icon 圖塊
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                
                // 中央文字區塊 (店家、發票號碼、日期)
                Expanded( // 佔據剩餘所有寬度
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 店家名稱，限制單行，過長就顯示 ...
                      Text(
                        invoice.merchantName ?? '未知店家',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoice.invoiceNumber ?? '無發票號碼',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        invoice.date != null ? DateUtilsHelper.formatDate(invoice.date!) : '未知日期',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 右側金額與刪除操作區
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end, // 靠右對齊
                  children: [
                    Text(
                      invoice.totalAmount != null ? '\$${invoice.totalAmount!.toStringAsFixed(0)}' : '-\$',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary, // 強調色
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 垃圾桶按鈕 (具有圓形點擊提示範圍)
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade400, // 危險操作使用紅色
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
