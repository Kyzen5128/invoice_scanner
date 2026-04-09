// 主畫面包裝元件 (Main Screen Wrapper)
// 
// 使用 go_router 的 StatefulNavigationShell 來包裝底部導覽列 (NavigationBar)，
// 使得切換分頁時，舊分頁的狀態能被保留 (保持原有滾動位置、輸入內容等)，不會被重新渲染。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 應用程式的底座畫面，包含 BottomNavigationBar
class MainScreen extends StatelessWidget {
  /// go_router 提供的殼，用來控制不同分頁的狀態與跳轉
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  /// 處理導覽列點擊事件
  void _onTap(int index) {
    // 透過 navigationShell 切換至對應的 branch (分支)
    navigationShell.goBranch(
      index,
      // 如果點擊目前已在的分頁，就回到該分頁的初始狀態 (如：滾回列表最上方)
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body 顯示 go_router 管理的目前分頁內容
      body: navigationShell,
      
      // 底部導覽列區域
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // 在導覽列上方加上淡淡的陰影，增加層次感
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        // Material 3 樣式的底部導覽列
        child: NavigationBar(
          height: 65, // 稍微縮減高度使其看起來不笨重
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          backgroundColor: Colors.white,
          elevation: 0,
          // 選中時的背景顯示顏色
          indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),     // 未選中圖示
              selectedIcon: Icon(Icons.receipt_long_rounded), // 選中圖示
              label: '我的發票',
            ),
            NavigationDestination(
              icon: Icon(Icons.document_scanner_outlined),
              selectedIcon: Icon(Icons.document_scanner_rounded),
              label: '掃描發票',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: '設定',
            ),
          ],
        ),
      ),
    );
  }
}
