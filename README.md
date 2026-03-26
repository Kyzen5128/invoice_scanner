# 📱 Invoice Scanner - 發票掃描 APP

> 使用 Google ML Kit 進行智能發票辨識的 Flutter 應用程式

---

## ✨ 功能特色

- 📸 **即時相機掃描** - 自動對焦的相機介面，支援閃光燈控制
- 🖼️ **相簿選取** - 從手機圖庫選擇發票照片進行辨識
- 🤖 **AI 文字辨識** - 使用 Google ML Kit 離線 OCR 技術
- 🎯 **智能解析** - 自動萃取發票號碼、日期、店家、金額
- ✏️ **手動修正** - 可編輯辨識錯誤的欄位
- 💾 **本地儲存** - 發票資料與照片永久保存在裝置
- 📋 **清單管理** - 瀏覽所有已儲存的發票記錄
- 5431
---

## 🏗️ 技術架構

### 核心技術棧

| 技術 | 用途 |
|------|------|
| ![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white) | 跨平台 UI 框架 |
| ![Riverpod](https://img.shields.io/badge/Riverpod-0175C2?logo=flutter&logoColor=white) | 狀態管理 |
| ![Google ML Kit](https://img.shields.io/badge/ML_Kit-4285F4?logo=google&logoColor=white) | 文字辨識引擎 |
| ![Go Router](https://img.shields.io/badge/Go_Router-02569B?logo=flutter&logoColor=white) | 導航路由管理 |
| ![Material 3](https://img.shields.io/badge/Material_3-757575?logo=material-design&logoColor=white) | 設計系統 |

### 依賴套件

```yaml
dependencies:
  flutter_riverpod: ^2.6.1           # 狀態管理
  go_router: ^14.6.2                 # 路由管理
  google_mlkit_text_recognition: ^0.13.1  # OCR 辨識
  camera: ^0.11.0+2                  # 相機功能
  image_picker: ^1.1.2               # 圖片選擇
  path_provider: ^2.1.5              # 檔案路徑
  uuid: ^4.5.1                       # 唯一 ID 生成
```

---

## 🔄 完整執行流程

```
📸 使用者拍照 / 選取圖片
         ↓
┌────────────────────────────────────────────┐
│  scanner_page.dart (UI 層)                 │
│  ├─ 相機預覽介面                            │
│  ├─ 拍照按鈕觸發                            │
│  └─ 圖庫選取觸發                            │
└────────────────────────────────────────────┘
         ↓
┌────────────────────────────────────────────┐
│  scanner_provider.dart (狀態管理層)        │
│  └─ processCapturedImage(imagePath)       │
└────────────────────────────────────────────┘
         ↓
┌────────────────────────────────────────────┐
│  ocr_service.dart (OCR 辨識層)            │
│  ├─ 呼叫 Google ML Kit                     │
│  └─ processImage() → 回傳原始文字          │
└────────────────────────────────────────────┘
         ↓
┌────────────────────────────────────────────┐
│  invoice_parser.dart (解析層)             │
│  ├─ 正規表達式匹配                          │
│  ├─ 萃取：發票號碼、日期、店名、金額        │
│  └─ parse() → ParsedInvoiceResult         │
└────────────────────────────────────────────┘
         ↓
┌────────────────────────────────────────────┐
│  invoice_entity.dart (資料層)             │
│  └─ 建立 InvoiceEntity 物件                │
└────────────────────────────────────────────┘
         ↓
         跳轉至明細頁面
         ↓
┌────────────────────────────────────────────┐
│  invoice_detail_page.dart (編輯頁面)      │
│  ├─ 顯示辨識結果                            │
│  ├─ 允許手動修正                            │
│  └─ 使用者點擊 ✓ 儲存按鈕                   │
└────────────────────────────────────────────┘
         ↓
┌────────────────────────────────────────────┐
│  invoice_detail_provider.dart (業務層)    │
│  └─ save() → 協調儲存流程                   │
└────────────────────────────────────────────┘
         ↓
┌────────────────────────────────────────────┐
│  local_storage_service.dart (儲存層)      │
│  ├─ copyImageToAppDirectory()             │
│  │   → 複製圖片到永久目錄                   │
│  └─ saveInvoice()                          │
│      → 存成 JSON 檔案                       │
└────────────────────────────────────────────┘
         ↓
    💾 儲存完成
```

---

## 📂 專案結構

```
lib/
├── core/                          # 核心通用模組
│   ├── constants/                 # 常數定義
│   ├── theme/                     # 主題配置
│   └── utils/                     # 工具函式
│
├── features/                      # 功能模組（依功能拆分）
│   ├── main/                      # 主頁面與底部導航
│   │   └── presentation/
│   │       └── main_screen.dart
│   │
│   ├── scanner/                   # 掃描功能
│   │   ├── data/
│   │   │   ├── ocr_service.dart           # Google ML Kit 整合
│   │   │   └── invoice_parser.dart        # 文字解析邏輯
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── invoice_entity.dart    # 發票資料模型
│   │   └── presentation/
│   │       ├── scanner_page.dart          # 相機介面
│   │       └── scanner_provider.dart      # 狀態管理
│   │
│   ├── invoice_detail/            # 發票明細與編輯
│   │   └── presentation/
│   │       ├── invoice_detail_page.dart
│   │       └── invoice_detail_provider.dart
│   │
│   └── invoice_list/              # 發票清單
│       └── presentation/
│           ├── invoice_list_page.dart
│           └── invoice_list_provider.dart
│
├── shared/                        # 共享元件
│   ├── services/
│   │   └── local_storage_service.dart     # 檔案儲存服務
│   └── widgets/
│       └── custom_app_bar.dart            # 自訂 AppBar
│
└── main.dart                      # 應用程式入口
```

---

## 📄 各檔案的職責

| 檔案 | 位置 | 功能 |
|------|------|------|
| `scanner_page.dart` | `features/scanner/presentation/` | 相機 UI，拍照按鈕觸發掃描 |
| `scanner_provider.dart` | `features/scanner/presentation/` | 協調 OCR 與 Parser 的業務邏輯 |
| `ocr_service.dart` | `features/scanner/data/` | 呼叫 Google ML Kit 辨識文字 |
| `invoice_parser.dart` | `features/scanner/data/` | 用正規表達式解析發票欄位 |
| `invoice_entity.dart` | `features/scanner/domain/entities/` | 定義發票資料結構 |
| `invoice_detail_page.dart` | `features/invoice_detail/presentation/` | 顯示並編輯發票內容 |
| `invoice_detail_provider.dart` | `features/invoice_detail/presentation/` | 處理儲存邏輯 |
| `local_storage_service.dart` | `shared/services/` | 實際寫入檔案系統 |

---

## 🎯 OCR 解析規則

### 1️⃣ 發票號碼
- **正規表達式**: `[A-Za-z]{2}-?\d{8}`
- **格式**: 2 個英文字母 + 8 個數字
- **範例**: `AB-12345678` 或 `AB12345678`（自動補上連字號）

### 2️⃣ 發票日期
- **正規表達式**: `(\d{4})[./-](\d{2})[./-](\d{2})`
- **支援格式**: `YYYY-MM-DD` / `YYYY/MM/DD` / `YYYY.MM.DD`
- **範例**: `2026-03-26`

### 3️⃣ 店家名稱
- **邏輯**: 取得文字的第一個非空白行
- **範例**: `全家便利商店`

### 4️⃣ 消費金額
- **正規表達式**: `(?:合計|總計|NT\$|\$)\s*:?\s*(\d+(?:,\d+)*)`
- **關鍵字**: 合計 / 總計 / NT$ / $
- **範例**: `合計 1,250` → `1250.0`（自動去除千分位逗號）

---

## 💾 資料儲存

### 儲存位置

```
DocumentsDirectory/invoices/
├── invoices.json              # 所有發票的 JSON 資料
└── images/
    ├── img_{UUID_1}.jpg       # 發票照片 1
    ├── img_{UUID_2}.jpg       # 發票照片 2
    └── img_{UUID_3}.jpg       # 發票照片 3
```

### JSON 結構範例

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "scannedAt": "2026-03-26T14:30:00.000",
    "imageLocalPath": "/path/to/img_{UUID}.jpg",
    "invoiceNumber": "AB-12345678",
    "date": "2026-03-25T00:00:00.000",
    "merchantName": "全家便利商店",
    "totalAmount": 150.0,
    "rawOcrText": "全家便利商店\nAB-12345678\n2026/03/25\n合計 150",
    "isManuallyEdited": false
  }
]
```

---

## 🚀 開始使用

### 環境需求

- Flutter SDK: `>=3.5.4 <4.0.0`
- Dart SDK: `>=3.5.0`
- Android: API 21+ (Android 5.0+)
- iOS: 12.0+

### 安裝與執行

```bash
# 1. 複製專案
git clone <repository-url>
cd invoice_scanner

# 2. 安裝依賴
flutter pub get

# 3. 執行應用程式
flutter run
```

### 權限設定

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>需要相機權限以掃描發票</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要相簿權限以選取發票照片</string>
```

---

## 🛠️ 開發技巧

### 修改 OCR 語言模型

在 `lib/features/scanner/data/ocr_service.dart` 中調整：

```dart
// 目前使用中文模型（含中文、英文、數字）
final TextRecognizer _textRecognizer =
    TextRecognizer(script: TextRecognitionScript.chinese);

// 其他選項：
// TextRecognitionScript.latin      - 英文
// TextRecognitionScript.japanese   - 日文
// TextRecognitionScript.korean     - 韓文
```

### 自訂解析規則

在 `lib/features/scanner/data/invoice_parser.dart` 中修改正規表達式。

---

## 🎨 設計特色

- **Material Design 3** - 使用最新設計規範
- **暗色模式支援** - 優雅的深色背景相機介面
- **流暢動畫** - 頁面切換與載入動畫
- **響應式設計** - 適配不同螢幕尺寸

---

## 🙏 致謝
```
                       _oo0oo_
                      o8888888o
                      88" . "88
                      (| -_- |)
                      0\  =  /0
                    ___/`---'\___
                  .' \\|     |// '.
                 / \\|||  :  |||// \
                / _||||| -:- |||||- \
               |   | \\\  -  /// |   |
               | \_|  ''\---/''  |_/ |
               \  .-\__  '-'  ___/-. /
             ___'. .'  /--.--\  `. .'___
          ."" '<  `.___\_<|>_/___.' >' "".
         | | :  `- \`.;`\ _ /`;.`/ - ` : | |
        \  \ `_.   \_ __\ /__ _/   .-` /  /
     =====`-.____`.___ \_____/___.-`___.-'=====
                       `=---='


     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

               佛祖保佑         永無BUG
```


