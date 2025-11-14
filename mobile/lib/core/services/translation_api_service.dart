import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

/// 翻譯 API 服務
/// 調用 Firebase Cloud Function `/translate` 端點
class TranslationApiService {
  final String baseUrl;
  final FirebaseAuth _auth;

  TranslationApiService({
    required this.baseUrl,
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  /// 翻譯文字
  /// @param text - 原文
  /// @param targetLang - 目標語言
  /// @returns 翻譯結果
  /// @throws Exception - 翻譯失敗
  Future<String> translateText(String text, String targetLang) async {
    try {
      // 獲取 Firebase ID Token
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get ID token');
      }

      // 發送請求
      final response = await http.post(
        Uri.parse('$baseUrl/translate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'text': text,
          'targetLang': targetLang,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Translation request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translatedText'] as String;
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        final data = jsonDecode(response.body);
        final retryAfter = data['retryAfter'] ?? 60;
        throw Exception('Rate limit exceeded. Please try again in $retryAfter seconds.');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Translation failed');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Translation error: ${e.toString()}');
    }
  }

  /// 批次翻譯（發送多個請求）
  /// @param texts - 原文列表
  /// @param targetLang - 目標語言
  /// @returns 翻譯結果列表
  Future<List<String>> translateBatch(List<String> texts, String targetLang) async {
    final results = <String>[];
    
    for (final text in texts) {
      try {
        final translated = await translateText(text, targetLang);
        results.add(translated);
      } catch (e) {
        // 批次翻譯中的單個錯誤不應中斷整個批次
        results.add(text); // 返回原文
      }
    }

    return results;
  }
}

