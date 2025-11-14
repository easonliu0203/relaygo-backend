import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// 司機車輛照片和公司資訊服務
class DriverVehicleService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 上傳車輛照片到 Firebase Storage
  Future<String?> uploadVehiclePhoto(File imageFile, String photoType) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ 用戶未登入');
        return null;
      }

      final String userId = currentUser.uid;
      final String fileName = 'vehicle_photo_${photoType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String storagePath = 'driver_vehicle_photos/$userId/$fileName';

      print('📤 開始上傳車輛照片: $storagePath');

      // 上傳到 Firebase Storage
      final Reference storageRef = _storage.ref().child(storagePath);
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;

      // 獲取下載 URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ 車輛照片上傳成功: $downloadUrl');

      // 保存到 Firestore
      await _saveVehiclePhotoToFirestore(photoType, downloadUrl, imageFile);

      return downloadUrl;
    } catch (e) {
      print('❌ 上傳車輛照片失敗: $e');
      return null;
    }
  }

  /// 保存車輛照片資訊到 Firestore
  Future<void> _saveVehiclePhotoToFirestore(
    String photoType,
    String url,
    File imageFile,
  ) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final String userId = currentUser.uid;
      final int fileSize = await imageFile.length();

      // 保存到 Firestore
      await _firestore
          .collection('driver_vehicle_photos')
          .doc('${userId}_$photoType')
          .set({
        'driverId': userId,
        'photoType': photoType,
        'url': url,
        'fileSize': fileSize,
        'uploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ 車輛照片資訊已保存到 Firestore');
    } catch (e) {
      print('❌ 保存車輛照片資訊失敗: $e');
    }
  }

  /// 載入司機的所有車輛照片
  Future<Map<String, String>> getVehiclePhotos() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ 用戶未登入');
        return {};
      }

      final String userId = currentUser.uid;

      final QuerySnapshot snapshot = await _firestore
          .collection('driver_vehicle_photos')
          .where('driverId', isEqualTo: userId)
          .get();

      final Map<String, String> photos = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String photoType = data['photoType'] as String;
        final String url = data['url'] as String;
        photos[photoType] = url;
      }

      print('✅ 載入了 ${photos.length} 張車輛照片');
      return photos;
    } catch (e) {
      print('❌ 載入車輛照片失敗: $e');
      return {};
    }
  }

  /// 刪除車輛照片
  Future<bool> deleteVehiclePhoto(String photoType) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ 用戶未登入');
        return false;
      }

      final String userId = currentUser.uid;

      // 從 Firestore 刪除
      await _firestore
          .collection('driver_vehicle_photos')
          .doc('${userId}_$photoType')
          .delete();

      print('✅ 車輛照片已刪除: $photoType');
      return true;
    } catch (e) {
      print('❌ 刪除車輛照片失敗: $e');
      return false;
    }
  }

  /// 保存靠行公司資訊
  Future<bool> saveCompanyInfo({
    required String companyName,
    required String companyTaxId,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ 用戶未登入');
        return false;
      }

      final String userId = currentUser.uid;

      // 驗證統一編號格式（8 位數字）
      if (companyTaxId.isNotEmpty && !RegExp(r'^\d{8}$').hasMatch(companyTaxId)) {
        print('❌ 統一編號格式錯誤');
        return false;
      }

      // 保存到 Firestore
      await _firestore.collection('driver_company_info').doc(userId).set({
        'driverId': userId,
        'companyName': companyName,
        'companyTaxId': companyTaxId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ 靠行公司資訊已保存');
      return true;
    } catch (e) {
      print('❌ 保存靠行公司資訊失敗: $e');
      return false;
    }
  }

  /// 載入靠行公司資訊
  Future<Map<String, String>?> getCompanyInfo() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ 用戶未登入');
        return null;
      }

      final String userId = currentUser.uid;

      final DocumentSnapshot doc = await _firestore
          .collection('driver_company_info')
          .doc(userId)
          .get();

      if (!doc.exists) {
        print('ℹ️ 尚未設定靠行公司資訊');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return {
        'companyName': data['companyName'] as String? ?? '',
        'companyTaxId': data['companyTaxId'] as String? ?? '',
      };
    } catch (e) {
      print('❌ 載入靠行公司資訊失敗: $e');
      return null;
    }
  }

  /// 獲取車輛照片統計資訊
  Future<Map<String, dynamic>> getVehiclePhotoStats() async {
    try {
      final photos = await getVehiclePhotos();

      // 定義必填照片類型
      final requiredExteriorPhotos = ['front_left', 'front_right', 'rear_left', 'rear_right'];
      final requiredInteriorPhotos = ['front_seat', 'rear_seat_1', 'trunk'];

      // 計算已上傳的必填照片數量
      int uploadedExterior = 0;
      int uploadedInterior = 0;

      for (var photoType in requiredExteriorPhotos) {
        if (photos.containsKey(photoType)) uploadedExterior++;
      }

      for (var photoType in requiredInteriorPhotos) {
        if (photos.containsKey(photoType)) uploadedInterior++;
      }

      return {
        'totalPhotos': photos.length,
        'uploadedExterior': uploadedExterior,
        'requiredExterior': requiredExteriorPhotos.length,
        'uploadedInterior': uploadedInterior,
        'requiredInterior': requiredInteriorPhotos.length,
        'isExteriorComplete': uploadedExterior == requiredExteriorPhotos.length,
        'isInteriorComplete': uploadedInterior == requiredInteriorPhotos.length,
        'isAllComplete': uploadedExterior == requiredExteriorPhotos.length &&
            uploadedInterior == requiredInteriorPhotos.length,
      };
    } catch (e) {
      print('❌ 獲取車輛照片統計失敗: $e');
      return {
        'totalPhotos': 0,
        'uploadedExterior': 0,
        'requiredExterior': 4,
        'uploadedInterior': 0,
        'requiredInterior': 3,
        'isExteriorComplete': false,
        'isInteriorComplete': false,
        'isAllComplete': false,
      };
    }
  }
}

