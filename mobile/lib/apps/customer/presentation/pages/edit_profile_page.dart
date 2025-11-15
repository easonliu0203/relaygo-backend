import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/providers/user_profile_provider.dart';
import '../../../../core/models/user_profile.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();  // ✅ 添加 email 控制器
  final _addressController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 載入現有資料
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  void _loadExistingData() {
    final profileState = ref.read(userProfileNotifierProvider);
    profileState.whenData((profile) {
      if (profile != null) {
        _firstNameController.text = profile.firstName ?? '';
        _lastNameController.text = profile.lastName ?? '';
        _phoneController.text = profile.phone ?? '';
        _emailController.text = profile.email ?? '';  // ✅ 載入 email
        _addressController.text = profile.address ?? '';
        _emergencyContactNameController.text =
            profile.emergencyContactName ?? '';
        _emergencyContactPhoneController.text =
            profile.emergencyContactPhone ?? '';
        _selectedDateOfBirth = profile.dateOfBirth;
        _selectedGender = profile.gender;
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();  // ✅ 釋放 email 控制器
    _addressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'TW'),
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(userProfileNotifierProvider.notifier).updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            dateOfBirth: _selectedDateOfBirth,
            gender: _selectedGender,
            emergencyContactName: _emergencyContactNameController.text.trim(),
            emergencyContactPhone:
                _emergencyContactPhoneController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('個人資料已更新'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失敗：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('編輯個人資料'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 基本資訊
            const Text(
              '基本資訊',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 16),

            // 姓氏
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: '姓氏',
                hintText: '請輸入姓氏',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請輸入姓氏';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 名字
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: '名字',
                hintText: '請輸入名字',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請輸入名字';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 電話
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '電話號碼',
                hintText: '請輸入電話號碼',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請輸入電話號碼';
                }
                // 簡單的電話號碼驗證
                if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                  return '請輸入有效的電話號碼（10位數字）';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ✅ 信箱（唯讀）
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '信箱',
                hintText: '來自 Google/Apple 登入',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F5F5),  // 灰色背景表示唯讀
              ),
              enabled: false,  // 設為唯讀
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '信箱為必填（來自第三方登入）';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 性別
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: '性別',
                prefixIcon: Icon(Icons.wc),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('男性')),
                DropdownMenuItem(value: 'female', child: Text('女性')),
                DropdownMenuItem(value: 'other', child: Text('其他')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // 生日
            InkWell(
              onTap: _selectDateOfBirth,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '生日',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedDateOfBirth != null
                      ? DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!)
                      : '請選擇生日',
                  style: TextStyle(
                    color: _selectedDateOfBirth != null
                        ? Colors.black87
                        : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 地址
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '地址',
                hintText: '請輸入地址',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // 緊急聯絡人
            const Text(
              '緊急聯絡人',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 16),

            // 緊急聯絡人姓名
            TextFormField(
              controller: _emergencyContactNameController,
              decoration: const InputDecoration(
                labelText: '緊急聯絡人姓名',
                hintText: '請輸入緊急聯絡人姓名',
                prefixIcon: Icon(Icons.contact_emergency),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 緊急聯絡人電話
            TextFormField(
              controller: _emergencyContactPhoneController,
              decoration: const InputDecoration(
                labelText: '緊急聯絡人電話',
                hintText: '請輸入緊急聯絡人電話',
                prefixIcon: Icon(Icons.phone_in_talk),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

