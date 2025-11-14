import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 創建 Firebase 測試帳號的腳本
/// 
/// 使用方法:
/// dart run scripts/create-test-accounts.dart
/// 
/// 這個腳本會自動創建以下測試帳號:
/// - customer.test@relaygo.com (客戶端測試帳號)
/// - driver.test@relaygo.com (司機端測試帳號)

void main() async {
  print('🔥 Firebase 測試帳號創建工具');
  print('================================');
  
  try {
    // 初始化 Firebase
    await Firebase.initializeApp();
    print('✅ Firebase 初始化成功');
    
    final auth = FirebaseAuth.instance;
    
    // 測試帳號配置
    final testAccounts = [
      {
        'email': 'customer.test@relaygo.com',
        'password': 'RelayGO2024!Customer',
        'displayName': '測試客戶',
        'type': 'customer',
      },
      {
        'email': 'driver.test@relaygo.com',
        'password': 'RelayGO2024!Driver',
        'displayName': '測試司機',
        'type': 'driver',
      },
    ];
    
    print('\n📝 開始創建測試帳號...');
    
    for (final account in testAccounts) {
      final email = account['email']!;
      final password = account['password']!;
      final displayName = account['displayName']!;
      final type = account['type']!;
      
      try {
        print('\n🔄 正在創建 $type 測試帳號: $email');
        
        // 嘗試創建用戶
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // 更新用戶顯示名稱
        await userCredential.user?.updateDisplayName(displayName);
        
        print('✅ 成功創建測試帳號: $email');
        print('   顯示名稱: $displayName');
        print('   用戶 ID: ${userCredential.user?.uid}');
        
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('⚠️  測試帳號已存在: $email');
          
          // 嘗試登入以驗證密碼
          try {
            await auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            print('✅ 測試帳號密碼驗證成功');
            await auth.signOut();
          } catch (loginError) {
            print('❌ 測試帳號密碼驗證失敗: $loginError');
            print('   請手動在 Firebase Console 中重設密碼');
          }
        } else {
          print('❌ 創建測試帳號失敗: $e');
        }
      }
    }
    
    print('\n🎉 測試帳號創建完成！');
    print('\n📋 測試帳號摘要:');
    print('客戶端測試帳號:');
    print('  📧 Email: customer.test@relaygo.com');
    print('  🔑 Password: RelayGO2024!Customer');
    print('\n司機端測試帳號:');
    print('  📧 Email: driver.test@relaygo.com');
    print('  🔑 Password: RelayGO2024!Driver');
    
    print('\n💡 使用說明:');
    print('1. 在應用程式中點擊「使用測試帳號」按鈕');
    print('2. 系統會自動填入對應的測試帳號資訊');
    print('3. 點擊「登入」按鈕進行認證');
    
  } catch (e) {
    print('❌ Firebase 初始化失敗: $e');
    print('\n🔧 可能的解決方案:');
    print('1. 確認 Firebase 配置檔案存在且正確');
    print('2. 確認網路連接正常');
    print('3. 確認 Firebase 專案設定正確');
    exit(1);
  }
}
