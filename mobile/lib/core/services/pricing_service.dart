import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 車型套餐模型
class VehiclePackage {
  final String id;
  final String name;
  final String description;
  final int duration; // 小時
  final double originalPrice;
  final double discountPrice;
  final double overtimeRate;
  final String vehicleCategory; // 'large' or 'small'
  final List<String> features;

  const VehiclePackage({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.originalPrice,
    required this.discountPrice,
    required this.overtimeRate,
    required this.vehicleCategory,
    required this.features,
  });

  factory VehiclePackage.fromJson(Map<String, dynamic> json) {
    return VehiclePackage(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      duration: json['duration'] as int,
      originalPrice: (json['originalPrice'] as num).toDouble(),
      discountPrice: (json['discountPrice'] as num).toDouble(),
      overtimeRate: (json['overtimeRate'] as num).toDouble(),
      vehicleCategory: json['vehicleCategory'] as String,
      features: List<String>.from(json['features'] as List),
    );
  }



  double get savings => originalPrice - discountPrice;
  double get savingsPercentage => (savings / originalPrice) * 100;
}

/// 價格配置服務
class PricingService {
  static final PricingService _instance = PricingService._internal();
  factory PricingService() => _instance;
  PricingService._internal();

  // Backend API 基礎 URL
  // 使用生產環境的 Railway Backend API
  // 即使在 Debug 模式下也使用生產環境，因為本地不再運行 Backend
  static const String _baseUrl = 'https://api.relaygo.pro/api';

  /// 獲取所有可用的車型套餐
  Future<List<VehiclePackage>> getAvailablePackages() async {
    try {
      debugPrint('[PricingService] 開始獲取價格配置');
      debugPrint('[PricingService] API URL: $_baseUrl/pricing/packages');

      // 從 Supabase API 獲取價格配置（添加 5 秒超時）
      final response = await http.get(
        Uri.parse('$_baseUrl/pricing/packages'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[PricingService] API 請求超時，使用模擬資料');
          throw TimeoutException('API 請求超時');
        },
      );

      debugPrint('[PricingService] API 回應狀態: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('[PricingService] API 回應資料: $data');

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> packagesJson = data['data'];
          final packages = packagesJson
              .map((json) => VehiclePackage.fromJson(json))
              .toList();
          debugPrint('[PricingService] 成功獲取 ${packages.length} 個套餐');
          return packages;
        } else {
          debugPrint('[PricingService] API 回應格式錯誤，使用模擬資料');
        }
      } else {
        debugPrint('[PricingService] API 請求失敗: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException catch (e) {
      debugPrint('[PricingService] 請求超時: $e');
    } on SocketException catch (e) {
      debugPrint('[PricingService] 網路連接失敗: $e');
    } catch (e) {
      debugPrint('[PricingService] 獲取價格配置失敗: $e');
    }

    // 降級到模擬資料
    debugPrint('[PricingService] 使用模擬資料');
    return _getMockPackages();
  }



  /// 獲取模擬套餐資料
  List<VehiclePackage> _getMockPackages() {
    return [
      // 大型車套餐
      const VehiclePackage(
        id: 'large_6h',
        name: '8-9人座 6小時方案',
        description: '適合6小時內的大型車包車服務',
        duration: 6,
        originalPrice: 70.0,
        discountPrice: 60.0,
        overtimeRate: 8.0,
        vehicleCategory: 'large',
        features: [
          '專業司機服務',
          '車輛保險保障',
          '24小時客服支援',
          '8-9人座寬敞空間',
          '大型行李箱',
          '適合團體出行',
        ],
      ),
      const VehiclePackage(
        id: 'large_8h',
        name: '8-9人座 8小時方案',
        description: '適合8小時內的大型車包車服務',
        duration: 8,
        originalPrice: 85.0,
        discountPrice: 75.0,
        overtimeRate: 8.0,
        vehicleCategory: 'large',
        features: [
          '專業司機服務',
          '車輛保險保障',
          '24小時客服支援',
          '8-9人座寬敞空間',
          '大型行李箱',
          '適合團體出行',
          '長時間包車優惠',
        ],
      ),
      // 小型車套餐
      const VehiclePackage(
        id: 'small_6h',
        name: '3-4人座 6小時方案',
        description: '適合6小時內的小型車包車服務',
        duration: 6,
        originalPrice: 50.0,
        discountPrice: 40.0,
        overtimeRate: 5.0,
        vehicleCategory: 'small',
        features: [
          '專業司機服務',
          '車輛保險保障',
          '24小時客服支援',
          '3-4人座舒適空間',
          '經濟實惠',
          '適合小家庭',
        ],
      ),
      const VehiclePackage(
        id: 'small_8h',
        name: '3-4人座 8小時方案',
        description: '適合8小時內的小型車包車服務',
        duration: 8,
        originalPrice: 60.0,
        discountPrice: 50.0,
        overtimeRate: 5.0,
        vehicleCategory: 'small',
        features: [
          '專業司機服務',
          '車輛保險保障',
          '24小時客服支援',
          '3-4人座舒適空間',
          '經濟實惠',
          '適合小家庭',
          '長時間包車優惠',
        ],
      ),
    ];
  }

  /// 根據乘客數量推薦合適的套餐
  List<VehiclePackage> getRecommendedPackages(int passengerCount) {
    // 這個方法將在獲取所有套餐後進行篩選
    // 暫時返回空列表，實際實作會在調用處處理
    return [];
  }

  /// 計算套餐的總費用（包含超時費用）
  double calculateTotalPrice(VehiclePackage package, int actualDuration) {
    if (actualDuration <= package.duration) {
      return package.discountPrice;
    }
    
    final overtimeHours = actualDuration - package.duration;
    return package.discountPrice + (overtimeHours * package.overtimeRate);
  }

  /// 格式化價格顯示
  String formatPrice(double price) {
    return '\$${price.toStringAsFixed(0)}';
  }
}
