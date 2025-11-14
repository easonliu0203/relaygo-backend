import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// 通知服務
///
/// 負責處理 FCM 推播通知的導航邏輯
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Logger _logger = Logger();

  // 全局 Navigator Key，用於在沒有 BuildContext 的情況下導航
  GlobalKey<NavigatorState>? _navigatorKey;

  // 通知點擊回調函數（由應用設置）
  Function(String bookingId)? _onNotificationClick;

  /// 設置 Navigator Key
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    _logger.i('📱 [通知服務] Navigator Key 已設置');
  }

  /// 設置通知點擊回調函數
  void setNotificationClickHandler(Function(String bookingId) handler) {
    _onNotificationClick = handler;
    _logger.i('📱 [通知服務] 通知點擊回調函數已設置');
  }

  /// 處理通知點擊
  void handleNotificationClick(RemoteMessage message) {
    _logger.i('📱 [通知服務] 用戶點擊通知: ${message.notification?.title}');
    _logger.i('📱 [通知服務] 通知資料: ${message.data}');

    final data = message.data;
    final type = data['type'];

    if (type == 'chat_message') {
      final bookingId = data['bookingId'];
      final messageId = data['messageId'];

      _logger.i('📱 [通知服務] 導航到聊天室: bookingId=$bookingId, messageId=$messageId');

      // 使用回調函數導航（由應用層實現具體導航邏輯）
      if (_onNotificationClick != null) {
        _onNotificationClick!(bookingId);
        _logger.i('📱 [通知服務] 已觸發通知點擊回調: $bookingId');
      } else {
        _logger.w('📱 [通知服務] 通知點擊回調函數未設置');
      }
    }
  }

  /// 處理前景通知（應用在前台時收到通知）
  void handleForegroundMessage(RemoteMessage message) {
    _logger.i('📱 [通知服務] 收到前景通知: ${message.notification?.title}');
    _logger.i('📱 [通知服務] 通知內容: ${message.notification?.body}');
    _logger.i('📱 [通知服務] 通知資料: ${message.data}');

    // 前景通知不自動導航，只記錄日誌
    // 可以在這裡顯示應用內通知（例如使用 SnackBar 或自定義通知）
    
    // 可選：顯示應用內通知
    _showInAppNotification(message);
  }

  /// 顯示應用內通知
  void _showInAppNotification(RemoteMessage message) {
    if (_navigatorKey == null) {
      return;
    }

    final context = _navigatorKey!.currentContext;
    if (context == null) {
      return;
    }

    final notification = message.notification;
    if (notification == null) {
      return;
    }

    // 使用 SnackBar 顯示通知
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title ?? '新訊息',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(notification.body ?? ''),
          ],
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '查看',
          onPressed: () {
            handleNotificationClick(message);
          },
        ),
      ),
    );
  }
}

