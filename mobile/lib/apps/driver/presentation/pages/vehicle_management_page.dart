import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../../../../core/services/driver_document_service.dart';
import '../../../../core/services/driver_vehicle_service.dart';
import 'privacy_policy_page.dart';

/// 車輛管理頁面 - 司機端文件上傳
class VehicleManagementPage extends ConsumerStatefulWidget {
  const VehicleManagementPage({super.key});

  @override
  ConsumerState<VehicleManagementPage> createState() => _VehicleManagementPageState();
}

class _VehicleManagementPageState extends ConsumerState<VehicleManagementPage> {
  final ImagePicker _picker = ImagePicker();
  final DriverDocumentService _documentService = DriverDocumentService();
  final DriverVehicleService _vehicleService = DriverVehicleService();

  // 文件上傳狀態
  final Map<String, String?> _documentUrls = {
    'id_card_front': null,
    'id_card_back': null,
    'drivers_license': null,
    'vehicle_registration': null,
    'insurance_policy': null,
    'police_clearance': null,
    'no_accident_record': null,
  };

  final Map<String, bool> _uploadingStatus = {
    'id_card_front': false,
    'id_card_back': false,
    'drivers_license': false,
    'vehicle_registration': false,
    'insurance_policy': false,
    'police_clearance': false,
    'no_accident_record': false,
  };

  // 車輛外觀照片上傳狀態
  final Map<String, String?> _vehicleExteriorUrls = {
    'front_left': null,
    'front_right': null,
    'rear_left': null,
    'rear_right': null,
  };

  final Map<String, bool> _vehicleExteriorUploadingStatus = {
    'front_left': false,
    'front_right': false,
    'rear_left': false,
    'rear_right': false,
  };

  // 車輛內裝照片上傳狀態
  final Map<String, String?> _vehicleInteriorUrls = {
    'front_seat': null,
    'rear_seat_1': null,
    'rear_seat_2': null,
    'rear_seat_3': null,
    'trunk': null,
  };

  final Map<String, bool> _vehicleInteriorUploadingStatus = {
    'front_seat': false,
    'rear_seat_1': false,
    'rear_seat_2': false,
    'rear_seat_3': false,
    'trunk': false,
  };

  // 靠行公司資訊
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyTaxIdController = TextEditingController();

  // 文件類型顯示名稱
  final Map<String, String> _documentNames = {
    'id_card_front': '身分證（正面）',
    'id_card_back': '身分證（背面）',
    'drivers_license': '駕照',
    'vehicle_registration': '行照',
    'insurance_policy': '保險單',
    'police_clearance': '良民證',
    'no_accident_record': '無肇事紀錄',
  };

  // 文件類型圖標
  final Map<String, IconData> _documentIcons = {
    'id_card_front': Icons.badge,
    'id_card_back': Icons.badge_outlined,
    'drivers_license': Icons.credit_card,
    'vehicle_registration': Icons.description,
    'insurance_policy': Icons.shield,
    'police_clearance': Icons.verified_user,
    'no_accident_record': Icons.check_circle,
  };

  // 車輛外觀照片顯示名稱
  final Map<String, String> _vehicleExteriorNames = {
    'front_left': '左前方',
    'front_right': '右前方',
    'rear_left': '左後方',
    'rear_right': '右後方',
  };

  // 車輛內裝照片顯示名稱
  final Map<String, String> _vehicleInteriorNames = {
    'front_seat': '前座區',
    'rear_seat_1': '後座區 1',
    'rear_seat_2': '後座區 2',
    'rear_seat_3': '後座區 3',
    'trunk': '後車箱',
  };

  // 車輛照片必填狀態
  final Map<String, bool> _vehicleExteriorRequired = {
    'front_left': true,
    'front_right': true,
    'rear_left': true,
    'rear_right': true,
  };

  final Map<String, bool> _vehicleInteriorRequired = {
    'front_seat': true,
    'rear_seat_1': true,
    'rear_seat_2': false,
    'rear_seat_3': false,
    'trunk': true,
  };

  @override
  void initState() {
    super.initState();
    _loadExistingDocuments();
    _loadVehiclePhotos();
    _loadCompanyInfo();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyTaxIdController.dispose();
    super.dispose();
  }

  /// 載入已上傳的文件
  Future<void> _loadExistingDocuments() async {
    try {
      final documents = await _documentService.getDriverDocuments();
      setState(() {
        _documentUrls.addAll(documents);
      });
    } catch (e) {
      print('❌ 載入文件失敗: $e');
    }
  }

  /// 載入車輛照片
  Future<void> _loadVehiclePhotos() async {
    try {
      final photos = await _vehicleService.getVehiclePhotos();
      setState(() {
        // 分配到外觀照片和內裝照片
        for (var entry in photos.entries) {
          if (_vehicleExteriorUrls.containsKey(entry.key)) {
            _vehicleExteriorUrls[entry.key] = entry.value;
          } else if (_vehicleInteriorUrls.containsKey(entry.key)) {
            _vehicleInteriorUrls[entry.key] = entry.value;
          }
        }
      });
    } catch (e) {
      print('❌ 載入車輛照片失敗: $e');
    }
  }

  /// 載入靠行公司資訊
  Future<void> _loadCompanyInfo() async {
    try {
      final companyInfo = await _vehicleService.getCompanyInfo();
      if (companyInfo != null) {
        setState(() {
          _companyNameController.text = companyInfo['companyName'] ?? '';
          _companyTaxIdController.text = companyInfo['companyTaxId'] ?? '';
        });
      }
    } catch (e) {
      print('❌ 載入靠行公司資訊失敗: $e');
    }
  }

  /// 保存靠行公司資訊
  Future<void> _saveCompanyInfo() async {
    try {
      final companyName = _companyNameController.text.trim();
      final companyTaxId = _companyTaxIdController.text.trim();

      if (companyName.isEmpty && companyTaxId.isEmpty) {
        return; // 兩者都為空，不需要保存
      }

      final success = await _vehicleService.saveCompanyInfo(
        companyName: companyName,
        companyTaxId: companyTaxId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('靠行公司資訊已保存'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存失敗，請檢查統一編號格式'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失敗：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 選擇並上傳圖片
  Future<void> _pickAndUploadImage(String documentType) async {
    try {
      // 1. 選擇圖片
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // 先選擇原始質量，後續再壓縮
      );

      if (image == null) return;

      setState(() {
        _uploadingStatus[documentType] = true;
      });

      // 2. 驗證和壓縮圖片
      final File? processedImage = await _validateAndCompressImage(File(image.path));
      
      if (processedImage == null) {
        setState(() {
          _uploadingStatus[documentType] = false;
        });
        return;
      }

      // 3. 上傳到 Firebase Storage
      final String? downloadUrl = await _uploadToFirebaseStorage(
        processedImage,
        documentType,
      );

      if (downloadUrl != null) {
        setState(() {
          _documentUrls[documentType] = downloadUrl;
          _uploadingStatus[documentType] = false;
        });

        // 4. 保存到資料庫
        await _saveDocumentToDatabase(documentType, downloadUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_documentNames[documentType]} 上傳成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _uploadingStatus[documentType] = false;
        });
      }
    } catch (e) {
      setState(() {
        _uploadingStatus[documentType] = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上傳失敗：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 選擇並上傳車輛照片
  Future<void> _pickAndUploadVehiclePhoto(
    String photoType,
    Map<String, String?> urlsMap,
    Map<String, bool> uploadingStatusMap,
  ) async {
    try {
      // 1. 選擇圖片
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null) return;

      setState(() {
        uploadingStatusMap[photoType] = true;
      });

      // 2. 驗證和壓縮圖片
      final File? processedImage = await _validateAndCompressImage(File(image.path));

      if (processedImage == null) {
        setState(() {
          uploadingStatusMap[photoType] = false;
        });
        return;
      }

      // 3. 上傳到 Firebase Storage（使用 DriverVehicleService）
      final String? downloadUrl = await _vehicleService.uploadVehiclePhoto(
        processedImage,
        photoType,
      );

      if (downloadUrl != null) {
        setState(() {
          urlsMap[photoType] = downloadUrl;
          uploadingStatusMap[photoType] = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getPhotoDisplayName(photoType)} 上傳成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          uploadingStatusMap[photoType] = false;
        });
      }
    } catch (e) {
      setState(() {
        uploadingStatusMap[photoType] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上傳失敗：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 獲取照片顯示名稱
  String _getPhotoDisplayName(String photoType) {
    return _vehicleExteriorNames[photoType] ??
           _vehicleInteriorNames[photoType] ??
           photoType;
  }

  /// 驗證和壓縮圖片
  Future<File?> _validateAndCompressImage(File imageFile) async {
    try {
      // 1. 檢查文件大小
      final int fileSize = await imageFile.length();
      final double fileSizeMB = fileSize / (1024 * 1024);

      // 2. 獲取圖片尺寸
      final image = await decodeImageFromList(await imageFile.readAsBytes());
      final int width = image.width;
      final int height = image.height;
      final int shortSide = width < height ? width : height;
      final int longSide = width > height ? width : height;

      print('📸 原始圖片 - 尺寸: ${width}x${height}, 大小: ${fileSizeMB.toStringAsFixed(2)} MB');

      // 3. 驗證短邊至少 800 像素
      if (shortSide < 800) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('圖片解析度過低，短邊至少需要 800 像素'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return null;
      }

      // 4. 計算目標尺寸（保持寬高比）
      int targetWidth = width;
      int targetHeight = height;

      // 如果長邊超過 1600，縮放到 1600
      if (longSide > 1600) {
        final double scale = 1600 / longSide;
        targetWidth = (width * scale).round();
        targetHeight = (height * scale).round();
        print('📐 需要縮放 - 目標尺寸: ${targetWidth}x${targetHeight}');
      }

      // 5. 壓縮圖片
      final String targetPath = imageFile.path.replaceAll('.jpg', '_compressed.jpg');
      
      // 初始質量設置
      int quality = 85;
      
      // 如果文件大小超過 1 MB，降低質量
      if (fileSizeMB > 1.0) {
        quality = 75;
        print('🗜️ 文件過大，降低質量到 $quality');
      }

      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: targetWidth,
        minHeight: targetHeight,
      );

      if (compressedFile == null) {
        throw Exception('圖片壓縮失敗');
      }

      final File compressedImageFile = File(compressedFile.path);
      final int compressedSize = await compressedImageFile.length();
      final double compressedSizeMB = compressedSize / (1024 * 1024);

      print('✅ 壓縮完成 - 大小: ${compressedSizeMB.toStringAsFixed(2)} MB');

      // 6. 如果壓縮後仍然超過 1 MB，進一步降低質量
      if (compressedSizeMB > 1.0) {
        print('⚠️ 壓縮後仍超過 1 MB，進一步降低質量');
        
        final String secondTargetPath = imageFile.path.replaceAll('.jpg', '_compressed2.jpg');
        final XFile? secondCompressedFile = await FlutterImageCompress.compressAndGetFile(
          compressedImageFile.absolute.path,
          secondTargetPath,
          quality: 60,
          minWidth: targetWidth,
          minHeight: targetHeight,
        );

        if (secondCompressedFile != null) {
          final File finalFile = File(secondCompressedFile.path);
          final int finalSize = await finalFile.length();
          final double finalSizeMB = finalSize / (1024 * 1024);
          print('✅ 二次壓縮完成 - 大小: ${finalSizeMB.toStringAsFixed(2)} MB');
          
          if (finalSizeMB > 1.0) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('圖片壓縮後仍超過 1 MB，請選擇較小的圖片'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return null;
          }
          
          return finalFile;
        }
      }

      return compressedImageFile;
    } catch (e) {
      print('❌ 圖片驗證/壓縮失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('圖片處理失敗：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// 上傳到 Firebase Storage
  Future<String?> _uploadToFirebaseStorage(File imageFile, String documentType) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      final String fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final String storagePath = 'driver_documents/${user.uid}/$fileName';

      print('📤 上傳到 Firebase Storage: $storagePath');

      final Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);
      final UploadTask uploadTask = storageRef.putFile(imageFile);

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ 上傳成功: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('❌ Firebase Storage 上傳失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上傳失敗：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// 保存文件資訊到資料庫
  Future<void> _saveDocumentToDatabase(String documentType, String downloadUrl) async {
    try {
      await _documentService.saveDocument(
        documentType: documentType,
        downloadUrl: downloadUrl,
      );
      print('💾 保存到資料庫成功: $documentType -> $downloadUrl');
    } catch (e) {
      print('❌ 保存到資料庫失敗: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('車輛管理'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 頁面說明
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: Color(0xFF4CAF50)),
                      SizedBox(width: 8),
                      Text(
                        '文件上傳要求',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRequirementItem('圖片短邊至少 800 像素'),
                  _buildRequirementItem('圖片長邊建議 1200 ～ 1600 像素'),
                  _buildRequirementItem('文件大小不超過 1 MB'),
                  _buildRequirementItem('支援格式：JPG、JPEG、PNG'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 隱私權政策與合作條約按鈕
          _buildPolicyButtons(),
          const SizedBox(height: 24),

          // 文件上傳區域
          _buildSectionTitle('文件上傳'),
          ..._documentUrls.keys.map((documentType) {
            return _buildDocumentUploadCard(documentType);
          }),
          const SizedBox(height: 24),

          // 車輛外觀照片區
          _buildSectionTitle('車輛外觀照片'),
          ..._vehicleExteriorUrls.keys.map((photoType) {
            return _buildVehiclePhotoCard(
              photoType,
              _vehicleExteriorNames[photoType]!,
              _vehicleExteriorRequired[photoType]!,
              _vehicleExteriorUrls,
              _vehicleExteriorUploadingStatus,
            );
          }),
          const SizedBox(height: 24),

          // 車輛內裝照片區
          _buildSectionTitle('車輛內裝照片'),
          ..._vehicleInteriorUrls.keys.map((photoType) {
            return _buildVehiclePhotoCard(
              photoType,
              _vehicleInteriorNames[photoType]!,
              _vehicleInteriorRequired[photoType]!,
              _vehicleInteriorUrls,
              _vehicleInteriorUploadingStatus,
            );
          }),
          const SizedBox(height: 24),

          // 靠行公司資訊區
          _buildSectionTitle('靠行公司資訊（選填）'),
          _buildCompanyInfoCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF4CAF50)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyPage(),
                ),
              );
            },
            icon: const Icon(Icons.privacy_tip),
            label: const Text('隱私權政策'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('功能開發中'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.handshake),
            label: const Text('合作條約'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadCard(String documentType) {
    final bool isUploading = _uploadingStatus[documentType] ?? false;
    final String? documentUrl = _documentUrls[documentType];
    final bool hasDocument = documentUrl != null && documentUrl.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文件標題
            Row(
              children: [
                Icon(
                  _documentIcons[documentType],
                  color: const Color(0xFF4CAF50),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _documentNames[documentType] ?? documentType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 上傳狀態
            if (isUploading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('正在處理圖片...'),
                  ],
                ),
              )
            else if (hasDocument)
              // 已上傳 - 顯示縮圖和重新上傳按鈕
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      documentUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _pickAndUploadImage(documentType),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新上傳'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              // 未上傳 - 顯示上傳按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _pickAndUploadImage(documentType),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('點擊上傳'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4CAF50),
        ),
      ),
    );
  }

  Widget _buildVehiclePhotoCard(
    String photoType,
    String displayName,
    bool isRequired,
    Map<String, String?> urlsMap,
    Map<String, bool> uploadingStatusMap,
  ) {
    final bool isUploading = uploadingStatusMap[photoType] ?? false;
    final String? photoUrl = urlsMap[photoType];
    final bool hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isRequired)
                  const Text(
                    ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const Spacer(),
                Text(
                  '不超過 1 MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isUploading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                    SizedBox(height: 8),
                    Text('正在處理圖片...'),
                  ],
                ),
              )
            else if (hasPhoto)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photoUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickAndUploadVehiclePhoto(
                        photoType,
                        urlsMap,
                        uploadingStatusMap,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新上傳'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _pickAndUploadVehiclePhoto(
                    photoType,
                    urlsMap,
                    uploadingStatusMap,
                  ),
                  icon: const Icon(Icons.upload),
                  label: const Text('點擊上傳'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: '公司名稱',
                hintText: '請輸入靠行公司名稱',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyTaxIdController,
              decoration: const InputDecoration(
                labelText: '統一編號',
                hintText: '請輸入 8 位數字',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 8,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^\d{8}$').hasMatch(value)) {
                    return '請輸入有效的 8 位數字統一編號';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveCompanyInfo,
                icon: const Icon(Icons.save),
                label: const Text('保存公司資訊'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

