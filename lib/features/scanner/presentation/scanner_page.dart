// 相機掃描頁面 (Camera Scanner Page)
// 
// 提供即時的相機預覽畫面與半透明的對焦遮罩，讓使用者進行發票或收據掃描。
// 支援切換閃光燈、從圖庫載入圖片，並在拍攝後自動引導至 OCR 處理狀態與明細修改頁。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';

import 'scanner_provider.dart';

/// 掃描頁面本身，需管控相機的生命週期，因此使用 ConsumerStatefulWidget
class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  // 控制原生的相機操作
  CameraController? _cameraController;
  // 記錄相機是否已準備就緒，避免在取得相機權限前渲染預覽畫面
  bool _isCameraInitialized = false;
  // 控制閃光燈的開關狀態
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    // 進入頁面時立即初始化相機
    _initializeCamera();
  }

  /// 尋找並初始化後置相機
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // 取得後置鏡頭，若無則預設使用第一個鏡頭
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // 設定相機控制器 (高畫質，不錄音以加速啟動並減少權限要求)
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      // 執行初始化並確保掛載狀態才更新畫面
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    // 離開頁面時必須釋放相機資源避免拖垮手機效能
    _cameraController?.dispose();
    super.dispose();
  }

  /// 執行拍照動作
  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isTakingPicture) return; // 避免連續重複點擊

    try {
      // 捕捉畫面的暫存檔案
      final XFile picture = await _cameraController!.takePicture();
      if (!mounted) return;
      // 呼叫 Provider 進行照片處理 (包含 OCR 與解析)
      ref.read(scannerProvider.notifier).processCapturedImage(picture.path);
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 監聽 scannerProvider 的狀態，供 UI 更新使用
    final state = ref.watch(scannerProvider);

    // 監聽 ScannerState 是否有變更，用來處理頁面跳轉或錯誤提示
    ref.listen<ScannerState>(scannerProvider, (previous, next) {
      if (next.result != null) {
        // 如果有辨識結果，跳轉到明細建立頁，並將結果以 extra 帶入
        context.push('/invoice/new', extra: next.result);
        // 重置掃描狀態，確保下次回到此頁時是乾淨的狀態
        ref.read(scannerProvider.notifier).reset();
      } else if (next.error != null) {
        // 如果有錯誤則顯示底部提醒 (SnackBar)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E28), // 尚未開啟相機前的暗色底圖
      body: state.isLoading 
          ? _buildLoadingState(context)
          : Stack(
              children: [
                // 底層 1：相機即時預覽畫面
                if (_isCameraInitialized)
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CameraPreview(_cameraController!),
                  )
                else
                  const Center(child: CircularProgressIndicator(color: Colors.white)),
                
                // 上層 2：底部的操作區塊 (包含拍照按鈕與對焦提示框)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.only(top: 16, bottom: 4),
                    decoration: BoxDecoration(
                      // 半透明的深色背景，讓相機畫面若隱若現
                      color: const Color(0xFF232533).withValues(alpha: 0.95),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 依據內部元件自動調整高度
                        children: [
                          const Text(
                            '請將鏡頭對準發票文字或 QrCode',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          // 繪製虛擬的掃描對焦框
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(width: 44, height: 3, color: Colors.black87),
                                      const SizedBox(height: 6),
                                      Container(width: 28, height: 3, color: Colors.black87),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(width: 16, height: 16, color: Colors.green.shade400),
                                          const SizedBox(width: 6),
                                          Container(width: 16, height: 16, color: Colors.green.shade400),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '適度調整掃描距離以便相機對焦',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          // 功能按鈕區列 (相簿、快門、閃光燈)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // 從圖庫選取相片按鈕
                                IconButton(
                                  icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
                                  onPressed: () {
                                    ref.read(scannerProvider.notifier).scanFromGallery();
                                  },
                                ),
                                // 大大的拍照快門鍵
                                InkWell(
                                  onTap: _takePicture,
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.green.shade400, width: 3),
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                // 閃光燈切換按鈕
                                IconButton(
                                  icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 28),
                                  onPressed: () async {
                                    if (_cameraController == null) return;
                                    setState(() {
                                      _isFlashOn = !_isFlashOn;
                                    });
                                    // 開啟或關閉相機閃光燈 (Torch 模式)
                                    await _cameraController!.setFlashMode(
                                        _isFlashOn ? FlashMode.torch : FlashMode.off);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 上層 3：頂部的模擬 App Bar，放在相機上方 (透明)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '掃描對獎',
                            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.help_outline, color: Colors.white), onPressed: () {}),
                              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () {}),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// AI 辨識載入時的等待動畫
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
          const SizedBox(height: 24),
          const Text('AI 智慧辨識中...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('請稍候，這可能需要幾秒鐘', style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
