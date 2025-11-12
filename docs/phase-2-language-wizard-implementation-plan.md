# 階段 2 實施計劃：語言精靈畫面

**日期**: 2025-10-17  
**階段**: Phase 2 - Language Wizard Screen  
**狀態**: 🚧 **進行中**

---

## 🎯 目標

創建一個簡潔、直觀的語言精靈畫面，讓用戶在首次登入時選擇偏好語言。

---

## 📋 任務清單

### 1. **創建語言精靈畫面 UI** 🚧

#### 檔案位置
- `mobile/lib/features/language_wizard/screens/language_wizard_screen.dart`
- `mobile/lib/features/language_wizard/widgets/language_option_tile.dart`

#### UI 設計要求
- ✅ 簡潔的標題：「選擇您的偏好語言」
- ✅ 副標題：「您可以隨時在設定中更改」
- ✅ 語言列表（帶國旗圖示和語言名稱）
- ✅ 預選系統語言（如果支援）
- ✅ 「確認」按鈕（選擇語言後啟用）
- ✅ 「跳過」按鈕（使用系統語言）

#### 支援的語言列表
```dart
final supportedLanguages = [
  {'code': 'zh-TW', 'name': '繁體中文', 'flag': '🇹🇼'},
  {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
  {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
  {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
  {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
  {'code': 'th', 'name': 'ไทย', 'flag': '🇹🇭'},
  {'code': 'ms', 'name': 'Bahasa Melayu', 'flag': '🇲🇾'},
  {'code': 'id', 'name': 'Bahasa Indonesia', 'flag': '🇮🇩'},
];
```

---

### 2. **偵測系統語言** 🚧

#### 實作方式
```dart
import 'dart:ui' as ui;

String detectSystemLanguage() {
  final locale = ui.PlatformDispatcher.instance.locale;
  final languageCode = locale.languageCode;
  final countryCode = locale.countryCode;
  
  // 處理繁體中文
  if (languageCode == 'zh') {
    if (countryCode == 'TW' || countryCode == 'HK') {
      return 'zh-TW';
    }
    // 簡體中文不支援，預設為繁體中文
    return 'zh-TW';
  }
  
  // 檢查是否在支援列表中
  final supportedCodes = ['en', 'ja', 'ko', 'vi', 'th', 'ms', 'id'];
  if (supportedCodes.contains(languageCode)) {
    return languageCode;
  }
  
  // 預設為繁體中文
  return 'zh-TW';
}
```

---

### 3. **創建語言精靈 Provider** 🚧

#### 檔案位置
- `mobile/lib/features/language_wizard/providers/language_wizard_provider.dart`

#### Provider 功能
```dart
@riverpod
class LanguageWizard extends _$LanguageWizard {
  @override
  FutureOr<String?> build() async {
    // 偵測系統語言
    return detectSystemLanguage();
  }
  
  // 選擇語言
  void selectLanguage(String languageCode) {
    state = AsyncValue.data(languageCode);
  }
  
  // 保存語言偏好
  Future<void> saveLanguagePreference(String userId, String languageCode) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('users').doc(userId).update({
      'preferredLang': languageCode,
      'inputLangHint': languageCode,
      'hasCompletedLanguageWizard': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // 跳過（使用系統語言）
  Future<void> skip(String userId) async {
    final systemLang = detectSystemLanguage();
    await saveLanguagePreference(userId, systemLang);
  }
}
```

---

### 4. **更新導航邏輯** 🚧

#### 檔案位置
- `mobile/lib/core/router/app_router.dart`（或類似的路由檔案）
- `mobile/lib/features/auth/screens/login_screen.dart`（或類似的登入畫面）

#### 導航流程
```
登入成功
  ↓
檢查 hasCompletedLanguageWizard
  ↓
  ├─ false → 導航到語言精靈畫面
  │           ↓
  │         選擇語言 / 跳過
  │           ↓
  │         保存到 Firestore
  │           ↓
  │         導航到主畫面
  │
  └─ true → 直接導航到主畫面
```

#### 實作範例
```dart
// 在登入成功後
Future<void> _handleLoginSuccess(String userId) async {
  final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();
  
  final userData = userDoc.data();
  final hasCompletedWizard = userData?['hasCompletedLanguageWizard'] ?? false;
  
  if (!hasCompletedWizard) {
    // 導航到語言精靈
    context.go('/language-wizard');
  } else {
    // 導航到主畫面
    context.go('/home');
  }
}
```

---

### 5. **創建語言選項 Widget** 🚧

#### 檔案位置
- `mobile/lib/features/language_wizard/widgets/language_option_tile.dart`

#### Widget 設計
```dart
class LanguageOptionTile extends StatelessWidget {
  final String languageCode;
  final String languageName;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;
  
  const LanguageOptionTile({
    required this.languageCode,
    required this.languageName,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: TextStyle(fontSize: 32)),
      title: Text(languageName),
      trailing: isSelected 
        ? Icon(Icons.check_circle, color: Colors.green)
        : Icon(Icons.circle_outlined),
      onTap: onTap,
      tileColor: isSelected 
        ? Colors.green.withOpacity(0.1)
        : null,
    );
  }
}
```

---

### 6. **測試用例** 🚧

#### 檔案位置
- `mobile/test/features/language_wizard/language_wizard_test.dart`

#### 測試項目
- ✅ 系統語言偵測正確
- ✅ 語言選擇功能正常
- ✅ 保存語言偏好到 Firestore
- ✅ 跳過功能使用系統語言
- ✅ 導航邏輯正確

---

## 📁 檔案結構

```
mobile/lib/features/language_wizard/
├── screens/
│   └── language_wizard_screen.dart
├── widgets/
│   └── language_option_tile.dart
├── providers/
│   └── language_wizard_provider.dart
│   └── language_wizard_provider.g.dart (generated)
└── utils/
    └── language_detector.dart

mobile/test/features/language_wizard/
└── language_wizard_test.dart
```

---

## 🎨 UI 設計草圖

```
┌─────────────────────────────────┐
│  選擇您的偏好語言                │
│  您可以隨時在設定中更改          │
├─────────────────────────────────┤
│                                 │
│  🇹🇼  繁體中文            ✓     │
│  🇺🇸  English                   │
│  🇯🇵  日本語                    │
│  🇰🇷  한국어                    │
│  🇻🇳  Tiếng Việt                │
│  🇹🇭  ไทย                       │
│  🇲🇾  Bahasa Melayu             │
│  🇮🇩  Bahasa Indonesia          │
│                                 │
├─────────────────────────────────┤
│  [跳過]              [確認]     │
└─────────────────────────────────┘
```

---

## 🔄 實施順序

1. ✅ **創建語言偵測工具** (`language_detector.dart`)
2. ✅ **創建語言選項 Widget** (`language_option_tile.dart`)
3. ✅ **創建語言精靈 Provider** (`language_wizard_provider.dart`)
4. ✅ **創建語言精靈畫面** (`language_wizard_screen.dart`)
5. ✅ **更新路由配置** (添加 `/language-wizard` 路由)
6. ✅ **更新登入邏輯** (檢查 `hasCompletedLanguageWizard`)
7. ✅ **創建測試用例** (`language_wizard_test.dart`)
8. ✅ **測試和驗證**
9. ✅ **Git 提交**

---

## 📝 備註

### 設計考量
- **簡潔性**: 畫面應該簡單直觀，不要過度複雜
- **可訪問性**: 使用大字體和清晰的圖示
- **國際化**: 語言名稱使用該語言的原生名稱
- **預設值**: 預選系統語言，減少用戶操作

### 技術考量
- **Riverpod**: 使用 Riverpod 進行狀態管理
- **Freezed**: 如果需要複雜的狀態，使用 Freezed
- **Firebase**: 直接更新 Firestore，不需要額外的 API

---

## ✅ 完成標準

- [ ] 語言精靈畫面 UI 完成
- [ ] 系統語言偵測功能正常
- [ ] 語言選擇和保存功能正常
- [ ] 導航邏輯正確
- [ ] 測試用例通過
- [ ] Git 提交完成

---

**計劃創建時間**: 2025-10-17  
**計劃創建者**: Augment Agent

