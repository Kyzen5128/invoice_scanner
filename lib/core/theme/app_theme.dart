// 全域主題設定檔案 (Global App Theme)
// 
// 負責定義整體的色彩計畫 (Color Scheme)、字體 (Google Fonts)、
// 以及共用元件 (按鈕、輸入框、AppBar) 的外觀樣式。
// 確保整個 App 的視覺體驗保持一致。

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  /// 取得預設的淺色主題 (Light Theme)
  static ThemeData get lightTheme {
    return ThemeData(
      // 啟用最新的 Material 3 設計語彙
      useMaterial3: true,
      
      // 設定全螢幕預設字體為思源黑體 (Noto Sans TC)
      textTheme: GoogleFonts.notoSansTcTextTheme(),
      
      // 核心色彩計畫配置
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5),  // 基礎種子色 (靛青色)
        primary: const Color(0xFF4F46E5),    // 主要顏色 (按鈕、強調元件)
        secondary: const Color(0xFF10B981),  // 次要顏色 (薄荷綠，用於成功、總計等)
        surface: Colors.white,               // 表面元件背景色 (卡片、對話框)
        brightness: Brightness.light,        // 定義為淺色模式
      ),
      
      // Scaffold 背景色 (帶有一點點灰的白色)
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      
      // 頂部導覽列 (AppBar) 的統一樣式
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF4F46E5),
        foregroundColor: Colors.white, // 文字與 Icon 的顏色
      ),
      
      // 實心按鈕 (ElevatedButton) 的統一樣式
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      
      // 外框按鈕 (OutlinedButton) 的統一樣式
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
        ),
      ),
      
      // 輸入文字框 (TextField) 的統一樣式
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        // 預設邊框樣式
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        // 啟用且未聚焦時的邊框
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        // 聚焦時的邊框樣式 (使用主要顏色)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
        ),
      ),
    );
  }
}
