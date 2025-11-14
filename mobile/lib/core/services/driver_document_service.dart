import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

/// 司機文件服務 - 處理文件上傳到資料庫的邏輯
class DriverDocumentService {
  static final DriverDocumentService _instance = DriverDocumentService._internal();
  factory DriverDocumentService() => _instance;
  DriverDocumentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  /// 保存文件資訊到 Firestore
  /// 
  /// 注意：這裡先保存到 Firestore，後續會通過 Outbox Pattern 同步到 Supabase
  Future<void> saveDocument({
    required String documentType,
    required String downloadUrl,
  }) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      final String driverId = user.uid;
      final Map<String, dynamic> documentData = {
        'driver_id': driverId,
        'type': documentType,
        'url': downloadUrl,
        'status': 'pending', // 待審核
        'uploaded_at': FieldValue.serverTimestamp(),
        'reviewed_at': null,
        'reviewed_by': null,
        'notes': null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      _logger.i('💾 保存文件到 Firestore: $documentType');

      // 使用 driver_id + type 作為文檔 ID，確保每種類型只有一個文件
      final String docId = '${driverId}_$documentType';

      await _firestore
          .collection('driver_documents')
          .doc(docId)
          .set(documentData, SetOptions(merge: true));

      _logger.i('✅ 文件保存成功: $docId');
    } catch (e) {
      _logger.e('❌ 保存文件失敗: $e');
      rethrow;
    }
  }

  /// 獲取司機的所有文件
  Future<Map<String, String>> getDriverDocuments() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      final String driverId = user.uid;

      _logger.i('📥 載入司機文件: $driverId');

      final QuerySnapshot snapshot = await _firestore
          .collection('driver_documents')
          .where('driver_id', isEqualTo: driverId)
          .get();

      final Map<String, String> documents = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String type = data['type'] as String;
        final String url = data['url'] as String;
        documents[type] = url;
      }

      _logger.i('✅ 載入文件成功: ${documents.length} 個文件');

      return documents;
    } catch (e) {
      _logger.e('❌ 載入文件失敗: $e');
      return {};
    }
  }

  /// 刪除文件
  Future<void> deleteDocument(String documentType) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      final String driverId = user.uid;
      final String docId = '${driverId}_$documentType';

      _logger.i('🗑️ 刪除文件: $docId');

      await _firestore
          .collection('driver_documents')
          .doc(docId)
          .delete();

      _logger.i('✅ 文件刪除成功');
    } catch (e) {
      _logger.e('❌ 刪除文件失敗: $e');
      rethrow;
    }
  }

  /// 獲取文件審核狀態
  Future<String?> getDocumentStatus(String documentType) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      final String driverId = user.uid;
      final String docId = '${driverId}_$documentType';

      final DocumentSnapshot doc = await _firestore
          .collection('driver_documents')
          .doc(docId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return data['status'] as String?;
    } catch (e) {
      _logger.e('❌ 獲取文件狀態失敗: $e');
      return null;
    }
  }
}

