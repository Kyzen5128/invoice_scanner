// 自訂應用程式頂部導覽列 (Custom App Bar)
// 
// 將 Material 預設的 AppBar 重新封裝，加上客製化的漸層背景色與圓角設計。
// 統一全站的頂部導覽列風格，使其具備現代感。

import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 顯示在正中央的標題文字
  final String title;
  /// 右方的操作按鈕陣列
  final List<Widget>? actions;
  /// 左方的操作按鈕 (例如返回鍵)
  final Widget? leading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // 套用強大的字體粗細與稍微拉開字距，增加質感
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontSize: 22,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 4, // 滾動時產生細小陰影
      
      // 將原本的背景預設設為透明，依靠 flexibleSpace 的漸層容器來上色
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      
      leading: leading,
      actions: actions,
      
      // 這裡繪製覆蓋在 AppBar 底下的背景容器
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          // 使用主要品牌色作漸層過渡效果
          gradient: LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // 底部採用圓角邊緣設計
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      // 告訴 Scaffold 這個 AppBar 是有圓角的，以避免剪裁問題
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    );
  }

  // 實作 PreferredSizeWidget 接口，告知 Scaffold 預設高度
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
