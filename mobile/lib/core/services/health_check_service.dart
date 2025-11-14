import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Backend 健康檢查服務
/// 
/// 用於檢查 Backend 服務是否可訪問，並在不可訪問時提供友好的提示
class HealthCheckService {
  // Backend 健康檢查 URL
  // Android 模擬器使用 10.0.2.2 訪問主機的 localhost
  static const String _healthCheckUrl = 'http://10.0.2.2:3000/health';
  
  // 超時時間
  static const Duration _timeout = Duration(seconds: 5);
  
  /// 檢查 Backend 是否可訪問
  /// 
  /// 返回：
  /// - true: Backend 可訪問且狀態正常
  /// - false: Backend 不可訪問或狀態異常
  static Future<bool> checkBackendHealth() async {
    try {
      debugPrint('[HealthCheck] 開始檢查 Backend 健康狀態...');
      debugPrint('[HealthCheck] URL: $_healthCheckUrl');
      
      final response = await http.get(
        Uri.parse(_healthCheckUrl),
      ).timeout(_timeout);
      
      debugPrint('[HealthCheck] 響應狀態碼: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          final status = data['status'];
          final service = data['service'];
          
          debugPrint('[HealthCheck] Backend 狀態: $status');
          debugPrint('[HealthCheck] 服務名稱: $service');
          
          if (status == 'OK') {
            debugPrint('[HealthCheck] ✅ Backend 健康狀態正常');
            return true;
          } else {
            debugPrint('[HealthCheck] ⚠️  Backend 狀態異常: $status');
            return false;
          }
        } catch (e) {
          debugPrint('[HealthCheck] ❌ 解析響應失敗: $e');
          return false;
        }
      } else {
        debugPrint('[HealthCheck] ❌ Backend 返回錯誤狀態碼: ${response.statusCode}');
        return false;
      }
    } on http.ClientException catch (e) {
      debugPrint('[HealthCheck] ❌ 網絡錯誤: $e');
      return false;
    } catch (e) {
      debugPrint('[HealthCheck] ❌ Backend 不可訪問: $e');
      return false;
    }
  }
  
  /// 顯示 Backend 不可訪問的提示對話框
  /// 
  /// 參數：
  /// - context: BuildContext
  /// - onRetry: 重試回調函數（可選）
  static void showBackendUnavailableDialog(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // 不允許點擊外部關閉
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Backend 服務不可訪問'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '無法連接到 Backend 服務。',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '請確認以下事項：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildCheckItem('Backend 服務已啟動'),
              _buildCheckItem('Backend 運行在端口 3000'),
              _buildCheckItem('網絡連接正常'),
              _buildCheckItem('防火牆未阻止連接'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 如何啟動 Backend：',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. 打開 Terminal\n'
                      '2. 進入 backend 目錄\n'
                      '3. 執行：npm run dev',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Backend URL: $_healthCheckUrl',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (onRetry != null)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重試'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
  
  /// 構建檢查項目
  static Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 顯示 Backend 健康檢查中的載入對話框
  static void showHealthCheckLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在檢查 Backend 服務...'),
          ],
        ),
      ),
    );
  }
  
  /// 執行健康檢查並顯示結果
  /// 
  /// 如果 Backend 不可訪問，會自動顯示提示對話框
  /// 
  /// 參數：
  /// - context: BuildContext
  /// - showLoading: 是否顯示載入對話框（默認：true）
  /// - onSuccess: 健康檢查成功的回調函數（可選）
  /// - onFailure: 健康檢查失敗的回調函數（可選）
  /// 
  /// 返回：
  /// - true: Backend 可訪問
  /// - false: Backend 不可訪問
  static Future<bool> checkAndShowResult(
    BuildContext context, {
    bool showLoading = true,
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
  }) async {
    if (showLoading) {
      showHealthCheckLoadingDialog(context);
    }
    
    final isHealthy = await checkBackendHealth();
    
    if (showLoading && context.mounted) {
      Navigator.pop(context); // 關閉載入對話框
    }
    
    if (isHealthy) {
      debugPrint('[HealthCheck] ✅ Backend 健康檢查通過');
      onSuccess?.call();
      return true;
    } else {
      debugPrint('[HealthCheck] ❌ Backend 健康檢查失敗');
      if (context.mounted) {
        showBackendUnavailableDialog(
          context,
          onRetry: () => checkAndShowResult(
            context,
            showLoading: showLoading,
            onSuccess: onSuccess,
            onFailure: onFailure,
          ),
        );
      }
      onFailure?.call();
      return false;
    }
  }
}

