import 'dart:io';
import 'package:flutter/foundation.dart';

/// 環境類型
enum Environment {
  /// 開發環境（本地開發服務器）
  development,
  
  /// 封測環境（Google Play 內部測試/封閉測試）
  staging,
  
  /// 正式環境（Google Play 正式發布）
  production,
}

/// 環境配置管理
/// 
/// 功能：
/// 1. 管理不同環境的 API 端點
/// 2. 根據平台（Android/iOS）和運行環境（模擬器/實機）自動選擇正確的 URL
/// 3. 支持開發、封測、正式三種環境
class EnvironmentConfig {
  /// 當前環境
  ///
  /// 可以通過以下方式設置：
  /// 1. 編譯時常量：flutter run --dart-define=ENVIRONMENT=staging
  /// 2. 代碼中直接修改（開發時）
  ///
  /// ✅ 默認使用 staging 環境（連接到 Railway 部署的 Backend，24/7 運行）
  /// 如需使用本地開發環境，請執行：flutter run --dart-define=ENVIRONMENT=development
  static Environment get currentEnvironment {
    const envString = String.fromEnvironment('ENVIRONMENT', defaultValue: 'staging');
    switch (envString) {
      case 'development':
        return Environment.development;
      case 'production':
        return Environment.production;
      default:
        return Environment.staging;
    }
  }

  /// 獲取 API 基礎 URL
  /// 
  /// 根據當前環境和平台自動選擇正確的 URL：
  /// 
  /// **開發環境**：
  /// - Android 模擬器：http://10.0.2.2:3001/api
  /// - iOS 模擬器：http://localhost:3001/api
  /// - 實機（需要手動配置）：http://<你的電腦IP>:3001/api
  /// 
  /// **封測環境**：
  /// - 所有設備：https://staging-api.yourdomain.com/api
  /// 
  /// **正式環境**：
  /// - 所有設備：https://api.yourdomain.com/api
  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return _getDevelopmentApiUrl();
      case Environment.staging:
        return _stagingApiUrl;
      case Environment.production:
        return _productionApiUrl;
    }
  }

  /// 開發環境 API URL（根據平台和設備類型自動選擇）
  static String _getDevelopmentApiUrl() {
    // 優先級 1: 檢查編譯時參數（用於實機測試）
    const customDevUrl = String.fromEnvironment('DEV_API_URL');
    if (customDevUrl.isNotEmpty) {
      debugPrint('[EnvironmentConfig] 使用自定義 DEV_API_URL: $customDevUrl');
      return customDevUrl;
    }

    // 優先級 2: 使用硬編碼的開發 IP（實機測試短期解決方案）
    // ⚠️ 實機測試時，請修改下面的 IP 為您的電腦區域網 IP
    // 使用 ipconfig (Windows) 或 ifconfig (Mac/Linux) 查找 IP
    //
    // 如果不想使用硬編碼 IP，請設置為空字符串: ''
    const hardcodedDevIp = '192.168.0.152'; // ✅ 您的電腦 IP

    // 如果設置了硬編碼 IP，優先使用（適用於實機測試）
    if (hardcodedDevIp.isNotEmpty) {
      const url = 'http://$hardcodedDevIp:3001/api';
      debugPrint('[EnvironmentConfig] 使用硬編碼開發 IP: $url');
      return url;
    }

    // 優先級 3: 根據平台自動選擇（適用於模擬器）
    if (Platform.isAndroid) {
      // Android 模擬器使用 10.0.2.2 訪問主機的 localhost
      debugPrint('[EnvironmentConfig] Android 模擬器，使用 10.0.2.2');
      return 'http://10.0.2.2:3001/api';
    } else if (Platform.isIOS) {
      // iOS 模擬器可以直接使用 localhost
      debugPrint('[EnvironmentConfig] iOS 模擬器，使用 localhost');
      return 'http://localhost:3001/api';
    } else {
      // 其他平台（Web、Desktop）
      debugPrint('[EnvironmentConfig] 其他平台，使用 localhost');
      return 'http://localhost:3001/api';
    }
  }

  /// 封測環境 API URL
  ///
  /// ✅ 已部署到 Railway，使用自定義網域
  static const String _stagingApiUrl = String.fromEnvironment(
    'STAGING_API_URL',
    defaultValue: 'https://api.relaygo.pro/api',
  );

  /// 正式環境 API URL
  ///
  /// ✅ 已部署到 Railway，使用自定義網域（與封測環境共用，正式上線前可更換為獨立服務器）
  static const String _productionApiUrl = String.fromEnvironment(
    'PRODUCTION_API_URL',
    defaultValue: 'https://api.relaygo.pro/api',
  );

  /// WebSocket 基礎 URL
  static String get wsBaseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return _getDevelopmentWsUrl();
      case Environment.staging:
        return _stagingWsUrl;
      case Environment.production:
        return _productionWsUrl;
    }
  }

  /// 開發環境 WebSocket URL
  static String _getDevelopmentWsUrl() {
    const customDevUrl = String.fromEnvironment('DEV_WS_URL');
    if (customDevUrl.isNotEmpty) {
      return customDevUrl;
    }

    if (Platform.isAndroid) {
      return 'ws://10.0.2.2:3001';
    } else if (Platform.isIOS) {
      return 'ws://localhost:3001';
    } else {
      return 'ws://localhost:3001';
    }
  }

  /// 封測環境 WebSocket URL
  static const String _stagingWsUrl = String.fromEnvironment(
    'STAGING_WS_URL',
    defaultValue: 'wss://api.relaygo.pro',
  );

  /// 正式環境 WebSocket URL
  static const String _productionWsUrl = String.fromEnvironment(
    'PRODUCTION_WS_URL',
    defaultValue: 'wss://api.relaygo.pro',
  );

  /// 是否為開發環境
  static bool get isDevelopment => currentEnvironment == Environment.development;

  /// 是否為封測環境
  static bool get isStaging => currentEnvironment == Environment.staging;

  /// 是否為正式環境
  static bool get isProduction => currentEnvironment == Environment.production;

  /// 是否啟用調試日誌
  static bool get enableDebugLog {
    // 開發和封測環境啟用調試日誌
    return isDevelopment || isStaging || kDebugMode;
  }

  /// API 請求超時時間（秒）
  static int get apiTimeout {
    switch (currentEnvironment) {
      case Environment.development:
        return 10; // 開發環境較長超時時間，方便調試
      case Environment.staging:
        return 8;
      case Environment.production:
        return 5;
    }
  }

  /// 打印當前環境配置（用於調試）
  static void printConfig() {
    if (!enableDebugLog) return;

    debugPrint('='.repeat(60));
    debugPrint('環境配置');
    debugPrint('='.repeat(60));
    debugPrint('當前環境: ${currentEnvironment.name}');
    debugPrint('API 基礎 URL: $apiBaseUrl');
    debugPrint('WebSocket URL: $wsBaseUrl');
    debugPrint('平台: ${Platform.operatingSystem}');
    debugPrint('調試模式: ${kDebugMode ? '是' : '否'}');
    debugPrint('API 超時: ${apiTimeout}秒');
    debugPrint('='.repeat(60));
  }
}

/// 實機開發配置助手
/// 
/// 用於在實機上測試時快速配置開發服務器 IP
class DeviceTestingHelper {
  /// 設置實機開發 API URL
  /// 
  /// 使用方法：
  /// 1. 找到你的電腦在區域網中的 IP 地址
  ///    - Windows: ipconfig
  ///    - Mac/Linux: ifconfig
  /// 2. 在 main.dart 中調用此方法（僅開發環境）
  /// 
  /// 示例：
  /// ```dart
  /// if (EnvironmentConfig.isDevelopment) {
  ///   DeviceTestingHelper.setDeviceTestingUrl('192.168.1.100');
  /// }
  /// ```
  static String getDeviceTestingUrl(String hostIp, {int port = 3001}) {
    return 'http://$hostIp:$port/api';
  }

  /// 常見的區域網 IP 範圍提示
  static const List<String> commonIpRanges = [
    '192.168.0.x',
    '192.168.1.x',
    '10.0.0.x',
    '172.16.0.x',
  ];

  /// 打印實機測試配置指南
  static void printDeviceTestingGuide() {
    debugPrint('');
    debugPrint('📱 實機測試配置指南');
    debugPrint('='.repeat(60));
    debugPrint('');
    debugPrint('1. 找到你的電腦 IP 地址：');
    debugPrint('   - Windows: 打開命令提示字元，執行 ipconfig');
    debugPrint('   - Mac/Linux: 打開終端，執行 ifconfig');
    debugPrint('   - 查找 "IPv4 地址" 或 "inet"，通常是 192.168.x.x');
    debugPrint('');
    debugPrint('2. 確保實機和電腦在同一 WiFi 網絡');
    debugPrint('');
    debugPrint('3. 使用以下命令運行應用：');
    debugPrint('   flutter run --dart-define=DEV_API_URL=http://<你的IP>:3001/api');
    debugPrint('');
    debugPrint('   例如：');
    debugPrint('   flutter run --dart-define=DEV_API_URL=http://192.168.1.100:3001/api');
    debugPrint('');
    debugPrint('4. 確保 Next.js 服務器監聽所有網絡接口：');
    debugPrint('   在 web-admin/package.json 中：');
    debugPrint('   "dev": "next dev -H 0.0.0.0 -p 3001"');
    debugPrint('');
    debugPrint('常見 IP 範圍: ${commonIpRanges.join(", ")}');
    debugPrint('='.repeat(60));
    debugPrint('');
  }
}

/// 環境切換擴展（用於字符串格式化）
extension on String {
  String repeat(int count) => List.filled(count, this).join();
}

