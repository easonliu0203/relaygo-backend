import 'dart:async' show unawaited, Timer, StreamSubscription, TimeoutException;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // 🔧 新增：用於 Method Channel
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';

/// 語音轉文字服務
/// 使用 OpenAI Whisper API（通過 Firebase Cloud Function）
class SttService {
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;
  SttService._internal();

  final _logger = Logger();
  AudioRecorder _recorder = AudioRecorder();
  final _auth = FirebaseAuth.instance;

  // 🔧 新增：Method Channel 用於音頻焦點管理
  static const MethodChannel _audioFocusChannel = MethodChannel('com.relaygo/audio_focus');

  // Firebase Cloud Function URL
  static const String _baseUrl =
      'https://asia-east1-ride-platform-f1676.cloudfunctions.net';

  // 錄音狀態
  bool _isRecording = false;
  String? _currentRecordingPath;
  Timer? _recordingTimer;
  int _recordingDuration = 0; // 秒

  // 最大錄音時長（秒）
  static const int maxRecordingDuration = 30;

  // 靜音檢測相關
  static const int silenceTimeoutSeconds = 3; // 靜音 3 秒後自動停止
  static const double silenceThresholdDb = -30.0; // 🔧 優化：調整為 -30 dB（更容易觸發靜音檢測）
  static const int soundConfirmationCount = 2; // 需要連續 2 次檢測到聲音才重置靜音計時
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _silenceTimer;
  int _silenceDuration = 0; // 當前靜音持續時長（秒）
  bool _isSilent = false; // 當前是否處於靜音狀態
  int _soundDetectionCount = 0; // 連續檢測到聲音的次數
  bool _isCheckingSilence = false; // 是否正在檢查靜音（防止重複調用）

  // 🔧 優化 1：音頻資源釋放鎖機制（防止競態條件）
  bool _isReleasingResources = false;

  // 🔧 修復：記錄錄音前的音樂播放狀態
  bool _wasAudioPlayingBeforeRecording = false;

  // 錄音狀態回調
  Function(int duration)? onRecordingProgress;
  Function(String audioPath)? onRecordingComplete; // 🔥 修改：傳遞錄音文件路徑
  Function(String error)? onRecordingError;
  Function(int silenceDuration)? onSilenceDetected; // 靜音檢測回調（傳入靜音持續秒數）
  Function(double amplitude)? onAmplitudeUpdate; // 音量更新回調（用於 UI 顯示）

  /// 檢查麥克風權限
  Future<bool> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      _logger.i('🎤 [STT] 麥克風權限狀態: $status');
      return status.isGranted;
    } catch (e) {
      _logger.e('🎤 [STT] 檢查麥克風權限失敗: $e');
      return false;
    }
  }

  /// 請求麥克風權限
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      _logger.i('🎤 [STT] 麥克風權限請求結果: $status');
      return status.isGranted;
    } catch (e) {
      _logger.e('🎤 [STT] 請求麥克風權限失敗: $e');
      return false;
    }
  }

  /// 開始錄音
  Future<bool> startRecording() async {
    try {
      // 檢查權限
      final hasPermission = await checkMicrophonePermission();
      if (!hasPermission) {
        final granted = await requestMicrophonePermission();
        if (!granted) {
          _logger.w('🎤 [STT] 麥克風權限未授予');
          onRecordingError?.call('麥克風權限未授予');
          return false;
        }
      }

      // 檢查是否已在錄音
      if (_isRecording) {
        _logger.w('🎤 [STT] 已在錄音中');
        return false;
      }

      // 🔧 優化 1：檢查是否正在釋放音頻資源（防止競態條件）
      if (_isReleasingResources) {
        _logger.w('🎤 [STT] 正在釋放音頻資源，請稍後再試');
        return false;
      }

      // 🔧 修復：記錄錄音前的音樂播放狀態
      _wasAudioPlayingBeforeRecording = await _checkAudioPlayingState();
      _logger.i('🎤 [STT] 錄音前音樂播放狀態: $_wasAudioPlayingBeforeRecording');

      // 🔧 優化：請求音頻焦點（暫停背景音樂）
      await _requestAudioFocus();

      // 獲取臨時目錄
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/recording_$timestamp.m4a';

      _logger.i('🎤 [STT] 開始錄音: $_currentRecordingPath');

      // 開始錄音
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc, // AAC 編碼（.m4a）
          bitRate: 128000, // 128 kbps
          sampleRate: 44100, // 44.1 kHz
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordingDuration = 0;
      _silenceDuration = 0;
      _isSilent = false;
      _soundDetectionCount = 0;

      // 啟動計時器
      _startRecordingTimer();

      // 啟動靜音檢測
      _startSilenceDetection();

      return true;
    } catch (e) {
      _logger.e('🎤 [STT] 開始錄音失敗: $e');
      onRecordingError?.call('開始錄音失敗: $e');
      return false;
    }
  }

  /// 停止錄音
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        _logger.w('🎤 [STT] 未在錄音中');
        return null;
      }

      _logger.i('🎤 [STT] 停止錄音');

      // 停止錄音
      final path = await _recorder.stop();

      _isRecording = false;
      _stopRecordingTimer();
      _stopSilenceDetection();

      if (path == null) {
        _logger.w('🎤 [STT] 錄音路徑為空');
        return null;
      }

      _logger.i('🎤 [STT] 錄音完成: $path, 時長: $_recordingDuration 秒');

      // 🚀 優化：立即觸發回調，不等待音頻焦點釋放
      // 這樣 STT 轉錄可以立即開始，不會被 100ms 延遲阻塞
      onRecordingComplete?.call(path);

      // 🔧 修復：在背景釋放音頻資源（不阻塞 STT 流程）
      // 在 Android Auto 環境下，需要明確釋放音頻焦點
      // 使用 unawaited() 表示我們不等待這個操作完成
      unawaited(_releaseAudioResources());

      return path;
    } catch (e) {
      _logger.e('🎤 [STT] 停止錄音失敗: $e');
      onRecordingError?.call('停止錄音失敗: $e');
      return null;
    }
  }

  /// 取消錄音
  Future<void> cancelRecording() async {
    try {
      if (!_isRecording) {
        return;
      }

      _logger.i('🎤 [STT] 取消錄音');

      // 停止錄音
      await _recorder.stop();

      _isRecording = false;
      _stopRecordingTimer();
      _stopSilenceDetection();

      // 🚀 優化：在背景釋放音頻資源（不阻塞）
      unawaited(_releaseAudioResources());

      // 刪除錄音檔案
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          _logger.i('🎤 [STT] 已刪除錄音檔案: $_currentRecordingPath');
        }
      }

      _currentRecordingPath = null;
    } catch (e) {
      _logger.e('🎤 [STT] 取消錄音失敗: $e');
    }
  }

  /// 檢查音頻播放狀態
  ///
  /// 🔧 修復：在錄音開始前檢查是否有音樂或其他音頻正在播放
  /// 這樣在錄音結束後，只有在錄音前確實有音樂播放的情況下，才恢復音樂播放
  ///
  /// @return true 如果有音頻正在播放，false 否則
  Future<bool> _checkAudioPlayingState() async {
    if (Platform.isAndroid) {
      try {
        final isPlaying = await _audioFocusChannel.invokeMethod<bool>('isAudioPlaying');
        return isPlaying ?? false;
      } catch (e) {
        _logger.e('🎤 [STT] 檢查音頻播放狀態失敗: $e');
        return false;
      }
    }
    // iOS 暫時返回 false（未實現）
    return false;
  }

  /// 請求音頻焦點
  ///
  /// ❌ 已移除：不再使用 audio_session 套件管理音頻焦點
  ///
  /// 原因：record 套件的 AudioRecorder 已經在內部管理音頻焦點
  /// 額外調用 session.setActive(true) 會創建第二個音頻焦點請求
  /// 導致釋放時無法正確恢復背景音樂
  ///
  /// 新策略：完全依賴 AudioRecorder 的內建音頻焦點管理
  /// 通過正確的 dispose() 和重新創建來確保音頻焦點釋放
  Future<void> _requestAudioFocus() async {
    // ❌ 不再需要手動請求音頻焦點
    // AudioRecorder.start() 會自動請求 AUDIOFOCUS_GAIN_TRANSIENT
    _logger.i('🎤 [STT] AudioRecorder 將自動請求音頻焦點（暫停背景音樂）');
  }

  /// 釋放音頻資源
  ///
  /// 🔧 修復：在 Android Auto 環境下，確保釋放音頻焦點
  /// 這樣 TTS 才能正常獲取音頻焦點並播放，背景音樂也能恢復播放
  ///
  /// 🔧 優化 1：添加鎖機制，防止快速連續錄音時的競態條件
  Future<void> _releaseAudioResources() async {
    // 🔧 優化 1：設置鎖標誌，防止在釋放資源期間開始新的錄音
    _isReleasingResources = true;

    try {
      _logger.i('🎤 [STT] 釋放音頻資源');

      // 🔧 修復：通過 dispose 和重新創建 recorder 來確保釋放音頻焦點
      //
      // 重要：record 套件的 AudioRecorder 在內部管理音頻焦點
      // - start() 時會請求 AUDIOFOCUS_GAIN_TRANSIENT（暫停背景音樂）
      // - stop() 時應該釋放音頻焦點，但在某些情況下（特別是 Android Auto）可能不會
      // - dispose() 會強制釋放所有資源，包括音頻焦點
      //
      // 策略：
      // 1. 調用 dispose() 強制釋放音頻焦點
      // 2. 重新創建 AudioRecorder 實例，準備下次錄音
      // 3. 添加延遲，確保系統有時間處理音頻焦點變更並通知其他應用恢復播放

      await _recorder.dispose();
      _recorder = AudioRecorder(); // 重新創建 recorder
      _logger.i('🎤 [STT] AudioRecorder 已 dispose 並重新創建，音頻焦點已釋放');

      // 🔧 修復：只有在錄音前確實有音樂播放的情況下，才恢復音樂播放
      //
      // 問題：之前的代碼無條件地調用 resumeBackgroundMusic()，導致即使錄音前沒有音樂播放，
      // 錄音結束後也會自動啟動音樂播放
      //
      // 解決方案：檢查 _wasAudioPlayingBeforeRecording 狀態，只有當錄音前有音樂播放時，
      // 才調用 resumeBackgroundMusic()
      if (Platform.isAndroid && _wasAudioPlayingBeforeRecording) {
        try {
          await _audioFocusChannel.invokeMethod('resumeBackgroundMusic');
          _logger.i('🎤 [STT] 錄音前有音樂播放，已通過 Method Channel 通知其他應用恢復播放');
        } catch (e) {
          _logger.e('🎤 [STT] 通過 Method Channel 通知其他應用恢復播放失敗: $e');
        }
      } else if (Platform.isAndroid) {
        _logger.i('🎤 [STT] 錄音前沒有音樂播放，不恢復播放');
      }

      // 🔧 優化 1：300ms 延遲在後台執行，不阻塞 STT 轉錄流程
      // 這個延遲確保系統有時間處理音頻焦點釋放並通知其他應用恢復播放
      await Future.delayed(const Duration(milliseconds: 300));

      _logger.i('🎤 [STT] 音頻焦點釋放完成，背景音樂應該恢復播放');

    } catch (e) {
      _logger.e('🎤 [STT] 釋放音頻資源失敗: $e');
    } finally {
      // 🔧 優化 1：無論成功或失敗，都要釋放鎖
      _isReleasingResources = false;
    }
  }

  /// 啟動錄音計時器
  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration++;
      onRecordingProgress?.call(_recordingDuration);

      // 達到最大時長，自動停止
      if (_recordingDuration >= maxRecordingDuration) {
        _logger.i('🎤 [STT] 達到最大錄音時長，自動停止');
        stopRecording();
      }
    });
  }

  /// 停止錄音計時器
  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  /// 啟動靜音檢測（使用輪詢方式）
  void _startSilenceDetection() {
    try {
      _logger.i('🎤 [STT] 啟動靜音檢測（閾值: ${silenceThresholdDb.toStringAsFixed(1)} dB）');

      // 重置狀態
      _silenceDuration = 0;
      _isSilent = false;
      _soundDetectionCount = 0;

      // 使用定時器輪詢音量（每 500ms 檢查一次）
      _silenceTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!_isRecording) {
          timer.cancel();
          return;
        }

        // 使用 Future 來處理異步操作，但不阻塞 Timer
        _checkSilence(timer);
      });
    } catch (e) {
      _logger.e('🎤 [STT] 啟動靜音檢測失敗: $e');
    }
  }

  /// 檢查靜音狀態（異步方法）
  Future<void> _checkSilence(Timer timer) async {
    // 防止重複調用
    if (_isCheckingSilence) {
      _logger.w('🎤 [STT] 上一次靜音檢查尚未完成，跳過本次檢查');
      return;
    }

    _isCheckingSilence = true;

    try {
      // 獲取當前音量
      final amplitude = await _recorder.getAmplitude();
      final currentDb = amplitude.current;

      _logger.i('🎤 [STT] 當前音量: ${currentDb.toStringAsFixed(1)} dB');

      // 通知 UI 更新音量顯示
      onAmplitudeUpdate?.call(currentDb);

      // 判斷是否為靜音
      final isSilentNow = currentDb < silenceThresholdDb;

      if (isSilentNow) {
        // 檢測到靜音，重置聲音檢測計數
        _soundDetectionCount = 0;

        // 如果之前不是靜音狀態，開始靜音計時
        if (!_isSilent) {
          _isSilent = true;
          _silenceDuration = 0;
          _logger.i('🎤 [STT] 檢測到靜音開始: ${currentDb.toStringAsFixed(1)} dB');
        } else {
          // 已經在靜音狀態，增加靜音持續時間
          _silenceDuration++;
          _logger.i('🎤 [STT] 靜音持續: $_silenceDuration 次 (${(_silenceDuration * 0.5).toStringAsFixed(1)} 秒)');

          // 通知 UI 更新靜音倒數
          onSilenceDetected?.call(_silenceDuration);

          // 達到靜音逾時（6 次 * 0.5 秒 = 3 秒）
          if (_silenceDuration >= 6) {
            _logger.i('🎤 [STT] 靜音逾時（3 秒），自動停止錄音');
            timer.cancel();
            _isCheckingSilence = false; // 重置標誌
            await stopRecording();
            return;
          }
        }
      } else {
        // 檢測到聲音
        if (_isSilent) {
          _soundDetectionCount++;
          _logger.i('🎤 [STT] 檢測到聲音: ${currentDb.toStringAsFixed(1)} dB (連續 $_soundDetectionCount/$soundConfirmationCount 次)');

          // 需要連續多次檢測到聲音才重置靜音計時（避免誤判）
          if (_soundDetectionCount >= soundConfirmationCount) {
            _isSilent = false;
            _silenceDuration = 0;
            _soundDetectionCount = 0;
            _logger.i('🎤 [STT] 確認有聲音，重置靜音計時');
          }
        }
      }
    } catch (e) {
      _logger.e('🎤 [STT] 獲取音量失敗: $e');
    } finally {
      _isCheckingSilence = false;
    }
  }

  /// 停止靜音檢測
  void _stopSilenceDetection() {
    _logger.i('🎤 [STT] 停止靜音檢測');

    // 取消音量監聽訂閱（如果有）
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    // 停止靜音計時器（輪詢計時器）
    _silenceTimer?.cancel();
    _silenceTimer = null;

    // 重置所有狀態
    _silenceDuration = 0;
    _isSilent = false;
    _soundDetectionCount = 0;
    _isCheckingSilence = false;
  }

  /// 語音轉文字
  /// @param audioPath - 音訊檔案路徑
  /// @param language - 語言代碼（zh-TW, en, ja, ko, vi, th, ms, id）
  /// @returns 轉錄文字
  Future<String> transcribe(String audioPath, String language) async {
    try {
      _logger.i('🎤 [STT] 開始轉錄: audioPath=$audioPath, language=$language');

      // 檢查檔案是否存在
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('音訊檔案不存在: $audioPath');
      }

      final fileSize = await file.length();
      _logger.i('🎤 [STT] 音訊檔案大小: $fileSize bytes');

      // 檢查檔案大小（Whisper API 限制為 25MB）
      const maxSize = 25 * 1024 * 1024; // 25MB
      if (fileSize > maxSize) {
        throw Exception('音訊檔案過大: $fileSize bytes (最大: $maxSize bytes)');
      }

      // 獲取 Firebase ID Token
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception('無法獲取 ID Token');
      }

      // 創建 multipart 請求
      final uri = Uri.parse('$_baseUrl/stt');
      final request = http.MultipartRequest('POST', uri);

      // 添加 Authorization header
      request.headers['Authorization'] = 'Bearer $idToken';

      // 添加音訊檔案
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioPath,
          filename: 'audio.m4a',
        ),
      );

      // 添加語言參數
      request.fields['language'] = language;

      _logger.i('🎤 [STT] 發送請求到 Firebase Cloud Function');

      // 發送請求
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('語音轉文字請求超時');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      _logger.i('🎤 [STT] 收到回應: statusCode=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['text'] as String;
        final duration = data['duration'] as int;

        _logger.i('🎤 [STT] 轉錄成功: text="$text", duration=${duration}ms');

        // 刪除臨時錄音檔案
        await _deleteAudioFile(audioPath);

        return text;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? '未知錯誤';
        throw Exception('語音轉文字失敗: $errorMessage');
      }
    } catch (e) {
      _logger.e('🎤 [STT] 轉錄失敗: $e');
      // 刪除臨時錄音檔案
      await _deleteAudioFile(audioPath);
      rethrow;
    }
  }

  /// 語音轉文字 + 翻譯（優化版，減少網路往返）
  /// @param audioPath - 音訊檔案路徑
  /// @param sourceLang - 來源語言代碼
  /// @param targetLang - 目標語言代碼
  /// @returns Map 包含 'text' (STT 結果) 和 'translatedText' (翻譯結果)
  Future<Map<String, String>> transcribeAndTranslate(
    String audioPath,
    String sourceLang,
    String targetLang,
  ) async {
    try {
      _logger.i('🎤 [STT+翻譯] 開始處理: audioPath=$audioPath, sourceLang=$sourceLang, targetLang=$targetLang');

      // 檢查檔案是否存在
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('音訊檔案不存在: $audioPath');
      }

      final fileSize = await file.length();
      _logger.i('🎤 [STT+翻譯] 音訊檔案大小: $fileSize bytes');

      // 檢查檔案大小（Whisper API 限制為 25MB）
      const maxSize = 25 * 1024 * 1024; // 25MB
      if (fileSize > maxSize) {
        throw Exception('音訊檔案過大: $fileSize bytes (最大: $maxSize bytes)');
      }

      // 獲取 Firebase ID Token
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception('無法獲取 ID Token');
      }

      // 創建 multipart 請求
      final uri = Uri.parse('$_baseUrl/sttAndTranslate');
      final request = http.MultipartRequest('POST', uri);

      // 添加 Authorization header
      request.headers['Authorization'] = 'Bearer $idToken';

      // 添加音訊檔案
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioPath,
          filename: 'audio.m4a',
        ),
      );

      // 添加語言參數
      request.fields['sourceLang'] = sourceLang;
      request.fields['targetLang'] = targetLang;

      _logger.i('🎤 [STT+翻譯] 發送請求到 Firebase Cloud Function');

      // 發送請求
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('STT+翻譯請求超時');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      _logger.i('🎤 [STT+翻譯] 收到回應: statusCode=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['text'] as String;
        final translatedText = data['translatedText'] as String;
        final duration = data['duration'] as int;
        final cached = data['cached'] as bool? ?? false;

        _logger.i('🎤 [STT+翻譯] 成功: text="$text", translatedText="$translatedText", duration=${duration}ms, cached=$cached');

        // 刪除臨時錄音檔案
        await _deleteAudioFile(audioPath);

        return {
          'text': text,
          'translatedText': translatedText,
        };
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? '未知錯誤';
        throw Exception('STT+翻譯失敗: $errorMessage');
      }
    } catch (e) {
      _logger.e('🎤 [STT+翻譯] 失敗: $e');
      // 刪除臨時錄音檔案
      await _deleteAudioFile(audioPath);
      rethrow;
    }
  }

  /// 刪除音訊檔案
  Future<void> _deleteAudioFile(String audioPath) async {
    try {
      final file = File(audioPath);
      if (await file.exists()) {
        await file.delete();
        _logger.i('🎤 [STT] 已刪除音訊檔案: $audioPath');
      }
    } catch (e) {
      _logger.e('🎤 [STT] 刪除音訊檔案失敗: $e');
    }
  }

  /// 獲取當前錄音狀態
  bool get isRecording => _isRecording;

  /// 獲取當前錄音時長（秒）
  int get recordingDuration => _recordingDuration;

  /// 獲取剩餘錄音時長（秒）
  int get remainingDuration => maxRecordingDuration - _recordingDuration;

  /// 獲取當前靜音持續時長（秒）
  int get silenceDuration => _silenceDuration;

  /// 獲取是否處於靜音狀態
  bool get isSilent => _isSilent;

  /// 釋放資源
  Future<void> dispose() async {
    await cancelRecording();
    _stopSilenceDetection();
    await _recorder.dispose();
  }
}

