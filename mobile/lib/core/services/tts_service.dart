import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tts_cache_manager.dart';

/// TTS 狀態枚舉
enum TtsState {
  idle, // 閒置狀態
  localStarting, // 本地 TTS 啟動中
  localPlaying, // 本地 TTS 播放中
  gptStarting, // GPT 語音啟動中
  gptPlaying, // GPT 語音播放中
}

/// TTS 失敗類型枚舉
enum TtsFailureType {
  startFailed, // 啟動失敗
  timeout, // 逾時
  routeError, // 路由錯誤
  unknown, // 未知錯誤
}

/// TTS 語音播報服務
///
/// Phase 1: 實作內建 TTS 播放功能
/// - 狀態管理（idle, localStarting, localPlaying）
/// - 看門狗機制（開始門檻 1000ms、失敗門檻 A <200ms、失敗門檻 B >3000ms）
/// - 互斥播放
/// - 語言自動設定
///
/// Phase 2: 定義失敗事件
/// - 失敗類型定義（TtsFailureType）
/// - 事件記錄方法
/// - 去抖機制（500ms）
///
/// Phase 3: GPT 語音備援流程
/// - 整合 OpenAI TTS API
/// - 音訊下載和播放
/// - GPT 備援開關（預設關閉）
///
/// Phase 4: 自動備援切換條件
/// - 只有在內建 TTS 失敗時才切換到 GPT 備援
/// - 檢查 GPT 備援開關是否啟用
/// - 記錄備援切換事件
///
/// Phase 5: 音訊快取機制
/// - 為相同的文字+語言組合快取 GPT 生成的音訊檔案
/// - 使用文字內容和語言代碼的 hash 作為快取 key
/// - 設定快取過期時間（7 天）
/// - 實作快取清理機制（避免佔用過多儲存空間）
/// - 快取大小限制（最多 50MB）
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Logger _logger = Logger();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TtsCacheManager _cacheManager = TtsCacheManager();

  TtsState _state = TtsState.idle;
  TtsState get state => _state;

  // ⚙️ GPT 備援開關（預設關閉，避免意外產生成本）
  bool _enableGptBackup = false;
  bool get enableGptBackup => _enableGptBackup;

  /// 設置 GPT 備援開關
  ///
  /// ⚠️ 警告：啟用 GPT 備援會在內建 TTS 失敗時調用 OpenAI API，產生費用
  void setEnableGptBackup(bool enable) {
    _enableGptBackup = enable;
    _logger.i('🔊 [TTS] GPT 備援開關: ${enable ? "啟用" : "關閉"}');
    _logEvent('tts_gpt_backup_toggle', {'enabled': enable});
  }

  // 看門狗計時器
  Timer? _startTimeoutTimer; // 啟動逾時計時器（1000ms）
  Timer? _playTimeoutTimer; // 播放逾時計時器（3000ms）
  DateTime? _playStartTime; // 播放開始時間（用於檢測過短播放）

  // 去抖機制
  String? _lastText; // 上次播放的文字
  DateTime? _lastPlayTime; // 上次播放的時間

  // GPT 備援相關
  String? _pendingGptText; // 待播放的 GPT 語音文字
  String? _pendingGptLanguage; // 待播放的 GPT 語音語言

  // 語言映射表（Flutter TTS 語言代碼）
  static const Map<String, String> _languageMap = {
    'zh-TW': 'zh-TW', // 繁體中文
    'en': 'en-US', // 英文
    'ja': 'ja-JP', // 日文
    'ko': 'ko-KR', // 韓文
    'vi': 'vi-VN', // 越南文
    'th': 'th-TH', // 泰文
    'ms': 'ms-MY', // 馬來文
    'id': 'id-ID', // 印尼文
  };

  // ========================================
  // Firebase Cloud Function TTS API 配置
  // ========================================

  /// Firebase Cloud Function TTS 端點
  /// ⚠️ 注意：使用 Firebase Cloud Function 調用 OpenAI TTS API
  /// API Key 安全存儲在 Google Cloud Secret Manager 中
  static const String _ttsEndpoint = 'https://tts-5bpfajwrga-de.a.run.app';

  /// 初始化 TTS 服務
  Future<void> initialize() async {
    try {
      // 初始化快取管理器
      await _cacheManager.initialize();

      // 設置 TTS 事件監聽器
      _flutterTts.setStartHandler(() {
        _onTtsStart();
      });

      _flutterTts.setCompletionHandler(() {
        _onTtsComplete();
      });

      _flutterTts.setErrorHandler((msg) {
        _onTtsError(msg);
      });

      _flutterTts.setCancelHandler(() {
        _onTtsCancel();
      });

      // 設置 TTS 參數
      await _flutterTts.setSpeechRate(0.5); // 語速（0.0-1.0）
      await _flutterTts.setVolume(1.0); // 音量（0.0-1.0）
      await _flutterTts.setPitch(1.0); // 音調（0.5-2.0）

      // ========================================
      // 🔧 藍牙音響播放修復
      // ========================================

      // iOS 音頻會話設置
      // 確保 TTS 可以通過藍牙音響播放
      if (Platform.isIOS) {
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.duckOthers,
          ],
          IosTextToSpeechAudioMode.spokenAudio,
        );
        _logger.i('🔊 [TTS] iOS 音頻會話設置完成（支援藍牙音響）');
      }

      // Android 音頻焦點設置
      // 確保 TTS 可以請求音頻焦點，讓藍牙音響接收音頻
      if (Platform.isAndroid) {
        await _flutterTts.setSharedInstance(true);

        // 設置音頻屬性為導航模式
        // 這會使用 USAGE_ASSISTANCE_NAVIGATION_GUIDANCE 和 AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
        // 效果：TTS 播放時會降低背景音樂音量（ducking），播放完成後恢復
        await _flutterTts.setAudioAttributesForNavigation();

        _logger.i('🔊 [TTS] Android 音頻焦點設置完成（支援藍牙音響 + 背景音樂降音）');
      }

      _logger.i('🔊 [TTS] 服務初始化成功');
    } catch (e) {
      _logger.e('🔊 [TTS] 服務初始化失敗: $e');
    }
  }

  /// 播放語音
  ///
  /// [text] 要播放的文字
  /// [language] 文字的語言代碼（zh-TW, en, ja, ko, vi, th, ms, id）
  Future<void> speak(String text, String language) async {
    try {
      // 去抖機制：同一句話在 500ms 內的重複點擊應該被忽略
      if (_shouldDebounce(text)) {
        _logger.d('🔊 [TTS] 去抖：忽略重複點擊（500ms 內）');
        _logEvent('tts_debounced', {'text': text, 'language': language});
        return;
      }

      // 互斥播放：停止當前播放
      if (_state != TtsState.idle) {
        _logger.d('🔊 [TTS] 互斥播放：停止當前播放');
        await stop();
      }

      // 更新去抖記錄
      _lastText = text;
      _lastPlayTime = DateTime.now();

      // 保存待播放的文字和語言（用於 GPT 備援）
      _pendingGptText = text;
      _pendingGptLanguage = language;

      // 設置語言
      final ttsLanguage = _languageMap[language] ?? 'en-US';
      await _flutterTts.setLanguage(ttsLanguage);
      _logger.i('🔊 [TTS] 設置語言: $language -> $ttsLanguage');

      // 更新狀態
      _setState(TtsState.localStarting);
      _logEvent('tts_local_start_requested', {
        'text': text,
        'language': language,
        'ttsLanguage': ttsLanguage,
      });

      // 啟動看門狗計時器
      _startWatchdogTimers();

      // 開始播放
      // Android: 使用 focus: true 請求音頻焦點，配合 setAudioAttributesForNavigation()
      // 效果：TTS 播放時會降低背景音樂音量（ducking），播放完成後恢復
      _playStartTime = DateTime.now();
      final result = await _flutterTts.speak(text, focus: true);

      if (result == 1) {
        _logger.i('🔊 [TTS] 播放請求已發送（已請求音頻焦點）');
      } else {
        _logger.w('🔊 [TTS] 播放請求失敗: result=$result');
        _onPlaybackFailed(TtsFailureType.startFailed, 'speak() returned $result');
      }
    } catch (e) {
      _logger.e('🔊 [TTS] 播放失敗: $e');
      _onPlaybackFailed(TtsFailureType.unknown, e.toString());
    }
  }

  /// 停止播放
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _cancelWatchdogTimers();
      _setState(TtsState.idle);
      _logger.i('🔊 [TTS] 播放已停止');
    } catch (e) {
      _logger.e('🔊 [TTS] 停止播放失敗: $e');
    }
  }

  /// 檢查是否應該去抖
  bool _shouldDebounce(String text) {
    if (_lastText == null || _lastPlayTime == null) {
      return false;
    }

    final isSameText = _lastText == text;
    final timeSinceLastPlay = DateTime.now().difference(_lastPlayTime!);
    final isWithinDebounceWindow = timeSinceLastPlay.inMilliseconds < 500;

    return isSameText && isWithinDebounceWindow;
  }

  /// 啟動看門狗計時器
  void _startWatchdogTimers() {
    // 取消舊的計時器
    _cancelWatchdogTimers();

    // 開始門檻：呼叫 TTS 播放後，必須在 ≤1000ms 內收到「開始播放」事件
    _startTimeoutTimer = Timer(const Duration(milliseconds: 1000), () {
      if (_state == TtsState.localStarting) {
        _logger.w('🔊 [TTS] 啟動逾時：1000ms 內未收到開始事件');
        _onPlaybackFailed(TtsFailureType.timeout, 'Start timeout (1000ms)');
      }
    });

    // 失敗門檻 B：如果呼叫後 >3000ms 仍未開始播放 → 視為逾時失敗
    _playTimeoutTimer = Timer(const Duration(milliseconds: 3000), () {
      if (_state == TtsState.localStarting) {
        _logger.w('🔊 [TTS] 播放逾時：3000ms 內未開始播放');
        _onPlaybackFailed(TtsFailureType.timeout, 'Play timeout (3000ms)');
      }
    });
  }

  /// 取消看門狗計時器
  void _cancelWatchdogTimers() {
    _startTimeoutTimer?.cancel();
    _startTimeoutTimer = null;
    _playTimeoutTimer?.cancel();
    _playTimeoutTimer = null;
  }

  /// TTS 開始播放事件
  void _onTtsStart() {
    // ⚠️ 重要：只有在 localStarting 狀態時才處理開始事件
    // 如果已經切換到 GPT 備援（gptStarting 或 gptPlaying），則忽略延遲的內建 TTS 事件
    if (_state != TtsState.localStarting) {
      _logger.w('🔊 [TTS] 忽略延遲的內建 TTS 開始事件（當前狀態：$_state）');

      // 停止內建 TTS 播放（避免與 GPT 語音衝突）
      _flutterTts.stop();

      return;
    }

    _logger.i('🔊 [TTS] 開始播放');
    _logEvent('tts_local_start', {});

    // 取消啟動逾時計時器（已成功啟動）
    _startTimeoutTimer?.cancel();
    _startTimeoutTimer = null;

    // 更新狀態
    _setState(TtsState.localPlaying);
    _logEvent('tts_local_playing', {});
  }

  /// TTS 播放完成事件
  void _onTtsComplete() {
    // ⚠️ 重要：只有在 localPlaying 狀態時才處理完成事件
    // 如果已經切換到 GPT 備援（gptStarting 或 gptPlaying），則忽略延遲的內建 TTS 事件
    if (_state != TtsState.localPlaying) {
      _logger.w('🔊 [TTS] 忽略延遲的內建 TTS 完成事件（當前狀態：$_state）');
      return;
    }

    _logger.i('🔊 [TTS] 播放完成');
    _logEvent('tts_local_end', {});

    // 檢查失敗門檻 A：如果開始播放後 <200ms 就結束 → 視為播放失敗
    if (_playStartTime != null) {
      final playDuration = DateTime.now().difference(_playStartTime!);
      if (playDuration.inMilliseconds < 200) {
        _logger.w('🔊 [TTS] 播放過短：${playDuration.inMilliseconds}ms < 200ms');
        _onPlaybackFailed(
          TtsFailureType.startFailed,
          'Play duration too short (${playDuration.inMilliseconds}ms)',
        );
        return;
      }
    }

    // 取消計時器
    _cancelWatchdogTimers();

    // 更新狀態
    _setState(TtsState.idle);
  }

  /// TTS 播放錯誤事件
  void _onTtsError(dynamic message) {
    _logger.e('🔊 [TTS] 播放錯誤: $message');
    _logEvent('tts_local_error', {'message': message.toString()});
    _onPlaybackFailed(TtsFailureType.unknown, message.toString());
  }

  /// TTS 播放取消事件
  void _onTtsCancel() {
    _logger.i('🔊 [TTS] 播放已取消');
    _cancelWatchdogTimers();
    _setState(TtsState.idle);
  }

  /// 播放失敗處理
  void _onPlaybackFailed(TtsFailureType failureType, String reason) {
    _logger.w('🔊 [TTS] 播放失敗: type=$failureType, reason=$reason');
    _logEvent('tts_local_failed', {
      'failureType': failureType.toString(),
      'reason': reason,
    });

    // 取消計時器
    _cancelWatchdogTimers();

    // 更新狀態
    _setState(TtsState.idle);

    // ✅ Phase 4: 自動備援切換條件
    // 只有在 GPT 備援開關啟用時，才切換到 GPT 語音
    if (_enableGptBackup && _pendingGptText != null && _pendingGptLanguage != null) {
      _logger.i('🔊 [TTS] GPT 備援開關已啟用，切換到 GPT 語音備援');
      _logEvent('tts_backup_switch', {
        'failureType': failureType.toString(),
        'reason': reason,
        'text': _pendingGptText,
        'language': _pendingGptLanguage,
      });

      // 調用 GPT 語音備援
      _speakWithGpt(_pendingGptText!, _pendingGptLanguage!);
    } else {
      if (!_enableGptBackup) {
        _logger.i('🔊 [TTS] GPT 備援開關未啟用，不切換到 GPT 語音');
      }
    }
  }

  /// 更新狀態
  void _setState(TtsState newState) {
    if (_state != newState) {
      _logger.d('🔊 [TTS] 狀態變更: $_state -> $newState');
      _state = newState;
    }
  }

  /// 記錄事件
  void _logEvent(String eventName, Map<String, dynamic> params) {
    _logger.d('🔊 [TTS] 事件: $eventName, 參數: $params');
    // TODO: 未來可以整合 Firebase Analytics 或其他分析工具
  }

  // ========================================
  // Phase 3: GPT 語音備援功能
  // ========================================

  /// 使用 GPT 語音備援播放
  ///
  /// ⚠️ 警告：此方法會調用 OpenAI API，產生費用
  ///
  /// [text] 要播放的文字
  /// [language] 文字的語言代碼
  Future<void> _speakWithGpt(String text, String language) async {
    try {
      _logger.i('🔊 [TTS] 開始 GPT 語音備援');
      _setState(TtsState.gptStarting);
      _logEvent('tts_gpt_start_requested', {
        'text': text,
        'language': language,
        'textLength': text.length,
      });

      // 1. 調用 OpenAI TTS API 生成音訊
      final audioFilePath = await _generateGptVoice(text, language);

      if (audioFilePath == null) {
        throw Exception('Failed to generate GPT voice');
      }

      _logger.i('🔊 [TTS] GPT 語音生成成功，開始播放');
      _logEvent('tts_gpt_generated', {
        'audioFilePath': audioFilePath,
      });

      // 2. 使用 audioplayers 播放音訊
      await _playGptAudio(audioFilePath);

    } catch (e, stackTrace) {
      _logger.e('🔊 [TTS] GPT 語音備援失敗: $e');
      _logger.e('Stack trace: $stackTrace');
      _logEvent('tts_gpt_failed', {
        'error': e.toString(),
        'text': text,
        'language': language,
      });
      _setState(TtsState.idle);
    }
  }

  /// 調用 Firebase Cloud Function TTS API 生成音訊
  ///
  /// [text] 要轉換的文字
  /// [language] 文字的語言代碼
  ///
  /// 返回音訊檔案路徑，失敗時返回 null
  Future<String?> _generateGptVoice(String text, String language) async {
    try {
      // 1. 檢查快取
      final cachedAudioPath = await _cacheManager.getCachedAudio(text, language);
      if (cachedAudioPath != null) {
        _logger.i('🔊 [TTS] 使用快取的 GPT 語音: $cachedAudioPath');
        _logEvent('tts_gpt_cache_hit', {
          'text': text,
          'language': language,
          'cachedPath': cachedAudioPath,
        });
        return cachedAudioPath;
      }

      _logger.i('🔊 [TTS] 快取未命中，調用 Firebase Cloud Function TTS API');
      _logEvent('tts_gpt_cache_miss', {
        'text': text,
        'language': language,
      });

      // 2. 獲取 Firebase ID Token
      final user = _auth.currentUser;
      if (user == null) {
        _logger.e('🔊 [TTS] 用戶未登入');
        _logEvent('tts_gpt_user_not_authenticated', {});
        return null;
      }

      final idToken = await user.getIdToken();
      if (idToken == null) {
        _logger.e('🔊 [TTS] 無法獲取 ID Token');
        _logEvent('tts_gpt_id_token_missing', {});
        return null;
      }

      _logger.i('🔊 [TTS] 調用 Firebase Cloud Function TTS API: language=$language, textLength=${text.length}');

      // 3. 調用 Firebase Cloud Function TTS API
      final response = await http.post(
        Uri.parse(_ttsEndpoint),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'language': language,
        }),
      ).timeout(
        const Duration(seconds: 60), // TTS 生成可能需要更長時間
        onTimeout: () {
          throw TimeoutException('Firebase Cloud Function TTS API 調用逾時');
        },
      );

      if (response.statusCode != 200) {
        _logger.e('🔊 [TTS] Firebase Cloud Function TTS API 調用失敗: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        _logEvent('tts_gpt_api_error', {
          'statusCode': response.statusCode,
          'responseBody': response.body,
        });
        return null;
      }

      // 4. 保存到快取
      final cachedPath = await _cacheManager.saveCachedAudio(text, language, response.bodyBytes);
      if (cachedPath != null) {
        _logger.i('🔊 [TTS] GPT 語音已快取: $cachedPath');
        _logEvent('tts_gpt_audio_cached', {
          'filePath': cachedPath,
          'fileSize': response.bodyBytes.length,
        });
        return cachedPath;
      }

      // 5. 如果快取失敗，保存到臨時目錄（fallback）
      final tempDir = await getTemporaryDirectory();
      final uuid = const Uuid().v4();
      final audioFilePath = '${tempDir.path}/tts_gpt_$uuid.mp3';
      final audioFile = File(audioFilePath);

      await audioFile.writeAsBytes(response.bodyBytes);

      _logger.i('🔊 [TTS] GPT 語音檔案已保存（臨時）: $audioFilePath');
      _logEvent('tts_gpt_audio_saved_temp', {
        'filePath': audioFilePath,
        'fileSize': response.bodyBytes.length,
      });

      return audioFilePath;

    } catch (e, stackTrace) {
      _logger.e('🔊 [TTS] 生成 GPT 語音失敗: $e');
      _logger.e('Stack trace: $stackTrace');
      _logEvent('tts_gpt_generation_error', {
        'error': e.toString(),
      });
      return null;
    }
  }

  /// 播放 GPT 語音音訊
  ///
  /// [audioFilePath] 音訊檔案路徑
  Future<void> _playGptAudio(String audioFilePath) async {
    try {
      // ========================================
      // 🔧 藍牙音響播放修復
      // ========================================

      // 設置音頻上下文，確保 GPT 語音可以通過藍牙音響播放
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [
              AVAudioSessionOptions.allowBluetooth,
              AVAudioSessionOptions.allowBluetoothA2DP,
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            ],
          ),
        ),
      );
      _logger.i('🔊 [TTS] AudioPlayer 音頻上下文設置完成（支援藍牙音響）');

      // 設置音訊播放完成監聽器
      _audioPlayer.onPlayerComplete.listen((_) {
        _logger.i('🔊 [TTS] GPT 語音播放完成');
        _logEvent('tts_gpt_end', {});
        _setState(TtsState.idle);

        // 清理臨時音訊檔案
        _cleanupGptAudioFile(audioFilePath);
      });

      // 設置音訊播放狀態監聽器
      _audioPlayer.onPlayerStateChanged.listen((state) {
        _logger.d('🔊 [TTS] GPT 音訊播放狀態: $state');

        if (state == PlayerState.playing) {
          _logger.i('🔊 [TTS] GPT 語音播放中');
          _setState(TtsState.gptPlaying);
          _logEvent('tts_gpt_playing', {});
        }
      });

      // 播放音訊
      _logger.i('🔊 [TTS] 開始播放 GPT 語音: $audioFilePath');
      _logEvent('tts_gpt_start', {
        'audioFilePath': audioFilePath,
      });

      await _audioPlayer.play(DeviceFileSource(audioFilePath));

    } catch (e, stackTrace) {
      _logger.e('🔊 [TTS] 播放 GPT 語音失敗: $e');
      _logger.e('Stack trace: $stackTrace');
      _logEvent('tts_gpt_playback_error', {
        'error': e.toString(),
        'audioFilePath': audioFilePath,
      });
      _setState(TtsState.idle);

      // 清理臨時音訊檔案
      _cleanupGptAudioFile(audioFilePath);
    }
  }

  /// 清理 GPT 語音臨時音訊檔案
  ///
  /// [audioFilePath] 音訊檔案路徑
  ///
  /// ⚠️ 注意：只清理臨時目錄中的檔案，不清理快取目錄中的檔案
  void _cleanupGptAudioFile(String audioFilePath) {
    try {
      // 檢查是否為臨時檔案（包含 'tts_gpt_' 且在臨時目錄中）
      if (audioFilePath.contains('cache/tts_gpt_') && audioFilePath.contains(RegExp(r'[0-9a-f-]{36}'))) {
        // 這是臨時檔案（UUID 格式），可以刪除
        final file = File(audioFilePath);
        if (file.existsSync()) {
          file.deleteSync();
          _logger.d('🔊 [TTS] GPT 語音臨時檔案已清理: $audioFilePath');
        }
      } else {
        // 這是快取檔案，不刪除
        _logger.d('🔊 [TTS] 保留快取檔案: $audioFilePath');
      }
    } catch (e) {
      _logger.w('🔊 [TTS] 清理 GPT 語音臨時檔案失敗: $e');
    }
  }

  /// 獲取快取統計資訊
  Map<String, dynamic> getCacheStats() {
    return _cacheManager.getCacheStats();
  }

  /// 清空所有快取
  Future<void> clearAllCache() async {
    await _cacheManager.clearAllCache();
  }

  /// 釋放資源
  void dispose() {
    _cancelWatchdogTimers();
    _flutterTts.stop();
    _audioPlayer.dispose();
    _logger.i('🔊 [TTS] 服務已釋放');
  }
}

