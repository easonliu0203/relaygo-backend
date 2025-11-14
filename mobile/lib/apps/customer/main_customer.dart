import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/firebase_options.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../shared/providers/app_providers.dart';
import 'presentation/app/customer_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 載入環境變數
    await dotenv.load(fileName: ".env");

    // 初始化 Supabase
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      debugPrint('✅ Supabase 初始化成功');
    } else {
      debugPrint('⚠️ Supabase 配置不完整，跳過初始化');
    }

    // 初始化 Firebase Core
    await Firebase.initializeApp(
      name: 'customer',
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 初始化 Firebase 服務
    await FirebaseService().initialize();

    // 初始化 Hive
    await Hive.initFlutter();

    // 設定系統 UI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // 設定螢幕方向
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e, stackTrace) {
    // 記錄初始化錯誤，但不阻止應用程式啟動
    debugPrint('❌ 初始化過程中發生錯誤: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  runApp(
    const ProviderScope(
      child: CustomerApp(),
    ),
  );
}
