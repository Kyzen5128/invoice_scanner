// 主程式進入點暨路由設定 (Main Entry & Router Configuration)
//
// 負責初始化 Flutter App，設定 Riverpod 狀態管理的作用域，
// 並使用 go_router 管理底部的導覽列(NavigationBar)與頁面跳轉。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/invoice_list/presentation/invoice_list_page.dart';
import 'features/main/presentation/main_screen.dart';
import 'features/scanner/presentation/scanner_page.dart';
import 'features/invoice_detail/presentation/invoice_detail_page.dart';
import 'features/scanner/domain/entities/invoice_entity.dart';

/// App 執行入口
void main() {
  // ProviderScope 是 Riverpod 的必須元件，用來儲存所有 Provider 的狀態
  runApp(const ProviderScope(child: InvoiceScannerApp()));
}

/// 路由管理設定 (GoRouter)
/// 這裡使用 StatefulShellRoute 來實作保留狀態的底部導覽列切換
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/scan', // 預設首頁為相機掃描頁面
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // MainScreen 是包含底部導覽列的容器外殼
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          // 分支一：我的發票清單
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (context, state) => const InvoiceListPage(),
              ),
            ],
          ),
          // 分支二：掃描發票 (預設開啟)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scan',
                builder: (context, state) => const ScannerPage(),
              ),
            ],
          ),
          // 分支三：設定頁面 (擴充預留)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => Scaffold(
                  appBar: AppBar(title: const Text('設定')),
                  body: const Center(child: Text('此分頁為擴充預留')),
                ),
              ),
            ],
          ),
        ],
      ),
      // 新增發票明細頁的路由
      GoRoute(
        path: '/invoice/new',
        builder: (context, state) {
          // 透過 extra 傳遞發票實體資料
          final invoice = state.extra as InvoiceEntity;
          return InvoiceDetailPage(invoice: invoice, isNew: true);
        },
      ),
      // 檢視現有發票明細的路由
      GoRoute(
        path: '/invoice/:id',
        builder: (context, state) {
          final invoice = state.extra as InvoiceEntity;
          return InvoiceDetailPage(invoice: invoice, isNew: false);
        },
      ),
    ],
  );
});

/// 應用程式主體 Widget
class InvoiceScannerApp extends ConsumerWidget {
  const InvoiceScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 取得我們定義好的路由
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: '發票掃描 APP',
      theme: AppTheme.lightTheme, // 統一的 Material 3 淺色主題
      routerConfig: router,
      debugShowCheckedModeBanner: false, // 隱藏右上方 Debug 標籤
    );
  }
}
