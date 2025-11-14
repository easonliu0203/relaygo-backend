import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final Logger _logger = Logger();
  
  // Firebase 服務實例
  late FirebaseAuth _auth;
  late FirebaseMessaging _messaging;
  late FirebaseCrashlytics _crashlytics;
  late FirebaseAnalytics _analytics;
  late FirebaseFirestore _firestore;
  late FirebaseDatabase _database;
  late FirebaseStorage _storage;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseMessaging get messaging => _messaging;
  FirebaseCrashlytics get crashlytics => _crashlytics;
  FirebaseAnalytics get analytics => _analytics;
  FirebaseFirestore get firestore => _firestore;
  FirebaseDatabase get database => _database;
  FirebaseStorage get storage => _storage;

  /// 獲取當前登入的用戶
  User? get currentUser => _auth.currentUser;

  /// 初始化 Firebase
  Future<void> initialize() async {
    try {
      _logger.i('正在初始化 Firebase...');

      // 初始化 Firebase Core (已在 main 中完成，這裡跳過)
      // await Firebase.initializeApp();

      // 初始化各個服務
      _auth = FirebaseAuth.instance;
      _messaging = FirebaseMessaging.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      _analytics = FirebaseAnalytics.instance;
      _firestore = FirebaseFirestore.instance;
      _database = FirebaseDatabase.instance;
      _storage = FirebaseStorage.instance;

      // 設定 Firestore 離線持久化
      try {
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        _logger.i('Firestore 本地快取已啟用');
      } catch (e) {
        _logger.w('Firestore 本地快取設定失敗', error: e);
        // 即使快取設定失敗，也不應該阻止應用程式啟動
      }

      // 設定 Crashlytics (非阻塞)
      try {
        await _setupCrashlytics();
      } catch (e) {
        _logger.w('Crashlytics 設定失敗', error: e);
      }

      // 設定 FCM (非阻塞)
      try {
        await _setupMessaging();
      } catch (e) {
        _logger.w('Firebase Messaging 設定失敗', error: e);
      }

      // 設定 Analytics (非阻塞)
      try {
        await _setupAnalytics();
      } catch (e) {
        _logger.w('Firebase Analytics 設定失敗', error: e);
      }

      _logger.i('Firebase 初始化完成');
    } catch (e, stackTrace) {
      _logger.e('Firebase 初始化失敗', error: e, stackTrace: stackTrace);
      // 不再重新拋出異常，允許應用程式繼續運行
    }
  }

  /// 設定 Crashlytics
  Future<void> _setupCrashlytics() async {
    try {
      // 在 debug 模式下禁用 Crashlytics
      if (kDebugMode) {
        await _crashlytics.setCrashlyticsCollectionEnabled(false);
      }
      
      // 設定自動收集錯誤
      FlutterError.onError = _crashlytics.recordFlutterFatalError;
      
      // 設定非同步錯誤處理
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
      
      _logger.i('Crashlytics 設定完成');
    } catch (e) {
      _logger.e('Crashlytics 設定失敗', error: e);
    }
  }

  /// 設定 Firebase Messaging
  Future<void> _setupMessaging() async {
    try {
      // 請求通知權限
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('用戶已授權推播通知');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        _logger.i('用戶已授權臨時推播通知');
      } else {
        _logger.w('用戶拒絕推播通知權限');
      }

      // 獲取 FCM Token
      String? token = await _messaging.getToken();
      if (token != null) {
        _logger.i('FCM Token: $token');
        // TODO: 將 token 發送到後端服務器
      }

      // 監聽 token 更新
      _messaging.onTokenRefresh.listen((token) {
        _logger.i('FCM Token 已更新: $token');
        // TODO: 將新 token 發送到後端服務器
      });

      _logger.i('Firebase Messaging 設定完成');
    } catch (e) {
      _logger.e('Firebase Messaging 設定失敗', error: e);
    }
  }

  /// 設定 Analytics
  Future<void> _setupAnalytics() async {
    try {
      // 在 debug 模式下禁用 Analytics
      if (kDebugMode) {
        await _analytics.setAnalyticsCollectionEnabled(false);
      }
      
      _logger.i('Firebase Analytics 設定完成');
    } catch (e) {
      _logger.e('Firebase Analytics 設定失敗', error: e);
    }
  }

  /// 記錄自定義事件
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      _logger.e('記錄事件失敗', error: e);
    }
  }

  /// 設定用戶屬性
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      _logger.e('設定用戶屬性失敗', error: e);
    }
  }

  /// 記錄錯誤到 Crashlytics
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    bool fatal = false,
    Iterable<Object> information = const [],
  }) async {
    try {
      await _crashlytics.recordError(
        exception,
        stackTrace,
        fatal: fatal,
        information: information,
      );
    } catch (e) {
      _logger.e('記錄錯誤失敗', error: e);
    }
  }

  /// 設定用戶 ID
  Future<void> setUserId(String? userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId ?? '');
      await _analytics.setUserId(id: userId);
    } catch (e) {
      _logger.e('設定用戶 ID 失敗', error: e);
    }
  }

  /// 清理資源
  Future<void> dispose() async {
    // Firebase 服務通常不需要手動清理
    _logger.i('Firebase 服務已清理');
  }
}
