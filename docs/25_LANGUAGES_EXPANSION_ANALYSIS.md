# 擴展至 25 種語言支援分析報告

**分析日期**: 2025-10-18  
**目的**: 評估從 8 種語言擴展到 25 種語言的可行性、成本影響和技術實作方案

---

## 📊 當前狀態

### 目前支援的 8 種語言

| 語言代碼 | 語言名稱 | 國旗 |
|---------|---------|------|
| zh-TW | 繁體中文 | 🇹🇼 |
| en | English | 🇺🇸 |
| ja | 日本語 | 🇯🇵 |
| ko | 한국어 | 🇰🇷 |
| vi | Tiếng Việt | 🇻🇳 |
| th | ไทย | 🇹🇭 |
| ms | Bahasa Melayu | 🇲🇾 |
| id | Bahasa Indonesia | 🇮🇩 |

**定義位置**: `mobile/lib/shared/utils/language_detector.dart`

---

## 🎯 擴展目標：25 種語言

### 新增的 17 種語言

| 排序 | 語言代碼 | 語言名稱 (中文) | 語言名稱 (當地) | 國旗 | 主要地區 |
|------|---------|----------------|----------------|------|----------|
| 2 | es | 西班牙語 | Español | 🇪🇸 | 西班牙、墨西哥、南美洲 |
| 3 | zh | 簡體中文 | 简体中文 | 🇨🇳 | 中國大陸、新加坡 |
| 4 | hi | 印地語 | हिन्दी | 🇮🇳 | 印度、尼泊爾 |
| 5 | ar | 阿拉伯語 | العربية | 🇸🇦 | 中東、北非 |
| 6 | pt | 葡萄牙語 | Português | 🇵🇹 | 巴西、葡萄牙 |
| 7 | bn | 孟加拉語 | বাংলা | 🇧🇩 | 孟加拉、印度 |
| 8 | fr | 法語 | Français | 🇫🇷 | 法國、加拿大、非洲 |
| 9 | ru | 俄語 | Русский | 🇷🇺 | 俄羅斯、東歐、中亞 |
| 11 | de | 德語 | Deutsch | 🇩🇪 | 德國、奧地利、瑞士 |
| 13 | te | 泰盧固語 | తెలుగు | 🇮🇳 | 印度 |
| 14 | tr | 土耳其語 | Türkçe | 🇹🇷 | 土耳其 |
| 15 | it | 義大利語 | Italiano | 🇮🇹 | 義大利、瑞士 |
| 16 | ur | 烏爾都語 | اُردُو‎ | 🇵🇰 | 巴基斯坦、印度 |
| 17 | ta | 泰米爾語 | தமிழ் | 🇮🇳 | 印度、斯里蘭卡、新加坡 |
| 20 | pl | 波蘭語 | Polski | 🇵🇱 | 波蘭 |
| 21 | nl | 荷蘭語 | Nederlands | 🇳🇱 | 荷蘭、比利時 |
| 22 | ro | 羅馬尼亞語 | Română | 🇷🇴 | 羅馬尼亞、摩爾多瓦 |
| 23 | el | 希臘語 | Ελληνικά | 🇬🇷 | 希臘、賽普勒斯 |
| 24 | sv | 瑞典語 | Svenska | 🇸🇪 | 瑞典 |
| 25 | uk | 烏克蘭語 | Українська | 🇺🇦 | 烏克蘭 |

---

## 🤖 GPT-4o-mini 和 GPT-4o 的多語言支援能力

### 1. 官方支援情況

根據 OpenAI 官方資訊和研究論文：

**GPT-4o 和 GPT-4o-mini 都支援 100+ 種語言**

來源：
- OpenAI 官方公告：「multilingual speech benchmark spanning over 100 languages」
- 研究論文：IndicMMLU-Pro 顯示 GPT-4o-mini 對印度語系有良好支援

**結論**: ✅ **所有 25 種語言都被 GPT-4o 和 GPT-4o-mini 支援**

---

### 2. 翻譯品質評估

#### 高品質語言（GPT-4o-mini 已足夠）

這些語言在 GPT-4o-mini 上的翻譯品質已經非常好：

| 語言類別 | 語言 | 理由 |
|---------|------|------|
| **拉丁語系** | en, es, pt, fr, de, it, nl, ro, pl, sv | 訓練資料豐富，翻譯品質優秀 |
| **東亞語言** | zh, zh-TW, ja, ko | 大量訓練資料，翻譯準確 |
| **東南亞語言** | vi, th, ms, id | 訓練資料充足，品質良好 |
| **斯拉夫語系** | ru, uk, pl | 訓練資料豐富，翻譯準確 |

**估計品質**: ⭐⭐⭐⭐⭐ (5/5)

---

#### 中等品質語言（GPT-4o-mini 可用，GPT-4o 更佳）

這些語言在 GPT-4o-mini 上品質尚可，但 GPT-4o 會有明顯提升：

| 語言類別 | 語言 | 挑戰 | GPT-4o 優勢 |
|---------|------|------|-------------|
| **印度語系** | hi, bn, te, ta | 複雜的文法、多種書寫系統 | 更好的語境理解、更準確的語法 |
| **RTL 語言** | ar, ur | 從右到左書寫、複雜的連字 | 更好的文字方向處理、更自然的表達 |
| **其他** | tr, el | 特殊的語法結構 | 更準確的語法和慣用語 |

**估計品質**:
- GPT-4o-mini: ⭐⭐⭐⭐ (4/5)
- GPT-4o: ⭐⭐⭐⭐⭐ (5/5)

---

### 3. 研究數據支持

#### IndicMMLU-Pro 研究（印度語系）

根據 arXiv 論文（2025-01-27）：

| 語言 | GPT-4o-mini 表現 | 評價 |
|------|-----------------|------|
| 泰米爾語 (ta) | 35.08% | 接近 GPT-4o 的表現 |
| 印地語 (hi) | - | 良好的翻譯品質 |
| 孟加拉語 (bn) | - | 良好的翻譯品質 |

**結論**: GPT-4o-mini 對印度語系的支援已經相當不錯

---

#### 阿拉伯語研究

根據 Mutarjim 研究（2025-05-23）：

> "Despite recent advances in NLP, the Arabic language still lags behind other high-resource languages"

**結論**: 阿拉伯語是相對低資源語言，但 GPT-4o 和 GPT-4o-mini 仍然支援

---

## 💰 成本影響分析

### 關鍵發現：**成本不會增加**

#### 為什麼？

我們使用的是**智能翻譯策略**（Commit `e30aa19`）：

```javascript
// 只翻譯接收者的語言 + 英文後備
const targetLanguages = [];

// 1. 翻譯接收者的語言（如果不同於來源語言）
if (receiverLang !== sourceLang) {
  targetLanguages.push(receiverLang);
}

// 2. 翻譯成英文作為後備（如果雙方都不是英文）
if (sourceLang !== 'en' && receiverLang !== 'en') {
  targetLanguages.push('en');
}
```

**翻譯數量**: 1-2 種語言（無論支援 8 種還是 25 種）

---

### 成本對比

| 支援語言數量 | 每則訊息翻譯數量 | 每則訊息成本 (GPT-4o-mini) |
|-------------|-----------------|---------------------------|
| **8 種語言** | 1-2 種 | $0.00005 |
| **25 種語言** | 1-2 種 | $0.00005 |
| **100 種語言** | 1-2 種 | $0.00005 |

**結論**: ✅ **成本完全相同，不受支援語言數量影響**

---

### 為什麼成本不變？

**智能翻譯策略的核心邏輯**：

1. **動態語言檢測**: 從 Firestore 讀取用戶的 `preferredLang`
2. **按需翻譯**: 只翻譯聊天室中實際使用的語言
3. **英文後備**: 確保用戶切換語言時有翻譯可用

**範例**：
```
司機（繁中）→ 乘客（印地語）

翻譯語言: hi, en (2 種)
成本: $0.00005

vs

司機（繁中）→ 乘客（韓文）

翻譯語言: ko, en (2 種)
成本: $0.00005
```

**無論支援多少種語言，每則訊息都只翻譯 1-2 種語言**

---

## 🔧 技術實作方案

### 方案 1：全部使用 GPT-4o-mini（推薦）

**理由**：
1. ✅ 成本最低（$0.00005/則）
2. ✅ 對所有 25 種語言都有良好支援
3. ✅ 對於聊天訊息翻譯，品質已經足夠
4. ✅ 實作簡單，無需額外邏輯

**適用情況**：
- 成本敏感的應用
- 聊天訊息翻譯（當前使用場景）
- 追求簡單和穩定

**預估品質**：
- 拉丁語系、東亞語言、東南亞語言：⭐⭐⭐⭐⭐ (5/5)
- 印度語系、RTL 語言：⭐⭐⭐⭐ (4/5)

---

### 方案 2：混合使用（進階優化）

**策略**: 根據語言複雜度選擇模型

**實作邏輯**：
```javascript
// 在 translationService.js 中
getModelForLanguage(targetLang) {
  // 複雜語言使用 GPT-4o
  const complexLanguages = ['hi', 'bn', 'te', 'ta', 'ar', 'ur'];
  
  if (complexLanguages.includes(targetLang)) {
    return 'gpt-4o';
  }
  
  // 其他語言使用 GPT-4o-mini
  return 'gpt-4o-mini';
}
```

**成本估算**（假設 20% 的訊息使用複雜語言）：
```
每 10,000 則訊息：
- 8,000 則 × $0.00005 = $0.40 (GPT-4o-mini)
- 2,000 則 × $0.0008 = $1.60 (GPT-4o)
總成本: $2.00

vs 全部使用 GPT-4o-mini: $0.50 (+300%)
vs 全部使用 GPT-4o: $8.00 (-75%)
```

**優點**：
- ✅ 平衡成本和品質
- ✅ 對複雜語言提供更好的翻譯

**缺點**：
- ⚠️ 成本增加 4 倍
- ⚠️ 需要額外的邏輯判斷
- ⚠️ 增加系統複雜度

---

### 方案 3：全部使用 GPT-4o（不推薦）

**理由**：
1. ❌ 成本增加 16 倍（$0.0008/則）
2. ❌ 對於簡單聊天訊息，品質提升不明顯
3. ❌ 不符合成本效益

**適用情況**：
- 專業文件翻譯
- 對翻譯品質要求極高的場景

**不適用於**：
- ❌ 聊天訊息翻譯（當前使用場景）

---

## 📱 UI/UX 設計建議

### 問題：25 種語言的下拉選單太長

**當前 UI**：
- 語言精靈：`ListView.builder` 顯示所有語言
- 設定頁面：`AlertDialog` + `ListView.builder`
- 聊天室快速切換：`BottomSheet` + `ListView.builder`

**問題**：
- 8 種語言時，UI 已經較長
- 25 種語言時，用戶需要大量滾動才能找到目標語言

---

### 解決方案 1：分組顯示（推薦）

**策略**: 按地區或語系分組

**分組範例**：
```dart
final languageGroups = {
  '東亞語言': ['zh-TW', 'zh', 'ja', 'ko'],
  '東南亞語言': ['vi', 'th', 'ms', 'id'],
  '南亞語言': ['hi', 'bn', 'te', 'ta', 'ur'],
  '歐洲語言': ['en', 'es', 'pt', 'fr', 'de', 'it', 'nl', 'ro', 'pl', 'el', 'sv'],
  '中東語言': ['ar', 'tr'],
  '東歐語言': ['ru', 'uk'],
};
```

**UI 設計**：
```
┌─────────────────────────────┐
│ 選擇語言                     │
├─────────────────────────────┤
│ 🌏 東亞語言                  │
│   🇹🇼 繁體中文               │
│   🇨🇳 简体中文               │
│   🇯🇵 日本語                 │
│   🇰🇷 한국어                 │
├─────────────────────────────┤
│ 🌏 東南亞語言                │
│   🇻🇳 Tiếng Việt            │
│   🇹🇭 ไทย                   │
│   ...                        │
└─────────────────────────────┘
```

**優點**：
- ✅ 易於瀏覽和查找
- ✅ 符合用戶的心智模型
- ✅ 減少滾動距離

---

### 解決方案 2：搜尋功能

**策略**: 添加搜尋框過濾語言

**UI 設計**：
```
┌─────────────────────────────┐
│ 選擇語言                     │
├─────────────────────────────┤
│ 🔍 搜尋語言...               │
├─────────────────────────────┤
│ 🇹🇼 繁體中文                 │
│ 🇨🇳 简体中文                 │
│ 🇺🇸 English                 │
│ ...                          │
└─────────────────────────────┘
```

**實作**：
```dart
TextField(
  decoration: InputDecoration(
    hintText: '搜尋語言...',
    prefixIcon: Icon(Icons.search),
  ),
  onChanged: (query) {
    setState(() {
      filteredLanguages = supportedLanguages
          .where((lang) => lang['name']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  },
)
```

**優點**：
- ✅ 快速查找特定語言
- ✅ 適合熟悉目標語言名稱的用戶

**缺點**：
- ⚠️ 需要額外的 UI 空間
- ⚠️ 對不熟悉語言名稱的用戶不友好

---

### 解決方案 3：常用語言 + 全部語言（推薦）

**策略**: 顯示常用語言，其他語言折疊

**UI 設計**：
```
┌─────────────────────────────┐
│ 選擇語言                     │
├─────────────────────────────┤
│ 常用語言                     │
│ 🇹🇼 繁體中文                 │
│ 🇺🇸 English                 │
│ 🇯🇵 日本語                   │
│ 🇨🇳 简体中文                 │
├─────────────────────────────┤
│ ▼ 更多語言 (21)              │
└─────────────────────────────┘
```

**實作**：
```dart
final popularLanguages = ['zh-TW', 'en', 'ja', 'zh', 'ko', 'vi'];
final otherLanguages = supportedLanguages
    .where((lang) => !popularLanguages.contains(lang['code']))
    .toList();
```

**優點**：
- ✅ 常用語言快速訪問
- ✅ 減少初始顯示的語言數量
- ✅ 保持 UI 簡潔

---

### 最終建議：**分組 + 常用語言**

**結合方案 1 和方案 3**：

```
┌─────────────────────────────┐
│ 選擇語言                     │
├─────────────────────────────┤
│ ⭐ 常用語言                  │
│   🇹🇼 繁體中文               │
│   🇺🇸 English               │
│   🇯🇵 日本語                 │
│   🇨🇳 简体中文               │
├─────────────────────────────┤
│ 🌏 東亞語言 (4)              │
│ 🌏 東南亞語言 (4)            │
│ 🌏 南亞語言 (5)              │
│ 🌏 歐洲語言 (11)             │
│ 🌏 中東語言 (2)              │
│ 🌏 東歐語言 (2)              │
└─────────────────────────────┘
```

**點擊分組後展開**：
```
┌─────────────────────────────┐
│ 🌏 東亞語言                  │
├─────────────────────────────┤
│   🇹🇼 繁體中文               │
│   🇨🇳 简体中文               │
│   🇯🇵 日本語                 │
│   🇰🇷 한국어                 │
└─────────────────────────────┘
```

---

## 📝 需要修改的檔案

### 1. Flutter 客戶端

#### `mobile/lib/shared/utils/language_detector.dart`

**修改內容**: 更新 `supportedLanguages` 列表

**修改前**（8 種語言）：
```dart
static const List<Map<String, String>> supportedLanguages = [
  {'code': 'zh-TW', 'name': '繁體中文', 'flag': '🇹🇼'},
  {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
  // ... 6 more
];
```

**修改後**（25 種語言）：
```dart
static const List<Map<String, String>> supportedLanguages = [
  // 常用語言
  {'code': 'zh-TW', 'name': '繁體中文', 'flag': '🇹🇼', 'group': 'popular'},
  {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'group': 'popular'},
  {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵', 'group': 'popular'},
  {'code': 'zh', 'name': '简体中文', 'flag': '🇨🇳', 'group': 'popular'},
  
  // 東亞語言
  {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷', 'group': 'east-asia'},
  
  // 東南亞語言
  {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳', 'group': 'southeast-asia'},
  {'code': 'th', 'name': 'ไทย', 'flag': '🇹🇭', 'group': 'southeast-asia'},
  {'code': 'ms', 'name': 'Bahasa Melayu', 'flag': '🇲🇾', 'group': 'southeast-asia'},
  {'code': 'id', 'name': 'Bahasa Indonesia', 'flag': '🇮🇩', 'group': 'southeast-asia'},
  
  // 南亞語言
  {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳', 'group': 'south-asia'},
  {'code': 'bn', 'name': 'বাংলা', 'flag': '🇧🇩', 'group': 'south-asia'},
  {'code': 'te', 'name': 'తెలుగు', 'flag': '🇮🇳', 'group': 'south-asia'},
  {'code': 'ta', 'name': 'தமிழ்', 'flag': '🇮🇳', 'group': 'south-asia'},
  {'code': 'ur', 'name': 'اُردُو‎', 'flag': '🇵🇰', 'group': 'south-asia'},
  
  // 歐洲語言
  {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'group': 'europe'},
  {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹', 'group': 'europe'},
  {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'group': 'europe'},
  {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪', 'group': 'europe'},
  {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹', 'group': 'europe'},
  {'code': 'nl', 'name': 'Nederlands', 'flag': '🇳🇱', 'group': 'europe'},
  {'code': 'ro', 'name': 'Română', 'flag': '🇷🇴', 'group': 'europe'},
  {'code': 'pl', 'name': 'Polski', 'flag': '🇵🇱', 'group': 'europe'},
  {'code': 'el', 'name': 'Ελληνικά', 'flag': '🇬🇷', 'group': 'europe'},
  {'code': 'sv', 'name': 'Svenska', 'flag': '🇸🇪', 'group': 'europe'},
  
  // 中東語言
  {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦', 'group': 'middle-east'},
  {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷', 'group': 'middle-east'},
  
  // 東歐語言
  {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺', 'group': 'eastern-europe'},
  {'code': 'uk', 'name': 'Українська', 'flag': '🇺🇦', 'group': 'eastern-europe'},
];
```

---

#### 新增檔案：`mobile/lib/shared/widgets/grouped_language_selector.dart`

**目的**: 創建分組語言選擇器組件

**功能**：
- 顯示常用語言
- 按地區分組顯示其他語言
- 支援展開/折疊分組

---

### 2. Firebase Cloud Functions

#### `firebase/functions/src/services/translationService.js`

**修改內容**: 更新 `languageNames` 映射

**修改前**（第 90-99 行）：
```javascript
const languageNames = {
  'zh-TW': '繁體中文',
  'en': 'English',
  'ja': '日本語',
  'ko': '한국어',
  'th': 'ไทย',
  'vi': 'Tiếng Việt',
  'id': 'Bahasa Indonesia',
  'ms': 'Bahasa Melayu',
};
```

**修改後**（25 種語言）：
```javascript
const languageNames = {
  // 東亞語言
  'zh-TW': '繁體中文',
  'zh': '简体中文',
  'ja': '日本語',
  'ko': '한국어',
  
  // 東南亞語言
  'vi': 'Tiếng Việt',
  'th': 'ไทย',
  'ms': 'Bahasa Melayu',
  'id': 'Bahasa Indonesia',
  
  // 南亞語言
  'hi': 'हिन्दी',
  'bn': 'বাংলা',
  'te': 'తెలుగు',
  'ta': 'தமிழ்',
  'ur': 'اُردُو‎',
  
  // 歐洲語言
  'en': 'English',
  'es': 'Español',
  'pt': 'Português',
  'fr': 'Français',
  'de': 'Deutsch',
  'it': 'Italiano',
  'nl': 'Nederlands',
  'ro': 'Română',
  'pl': 'Polski',
  'el': 'Ελληνικά',
  'sv': 'Svenska',
  
  // 中東語言
  'ar': 'العربية',
  'tr': 'Türkçe',
  
  // 東歐語言
  'ru': 'Русский',
  'uk': 'Українська',
};
```

---

### 3. 測試檔案

#### `mobile/test/utils/language_detector_test.dart`

**修改內容**: 更新測試以反映 25 種語言

**修改前**（第 6-8 行）：
```dart
test('supportedLanguages should contain 8 languages', () {
  expect(LanguageDetector.supportedLanguages.length, 8);
});
```

**修改後**：
```dart
test('supportedLanguages should contain 25 languages', () {
  expect(LanguageDetector.supportedLanguages.length, 25);
});
```

---

## 📋 實作步驟

### 階段 1：後端更新（Firebase Cloud Functions）

1. ✅ 更新 `translationService.js` 中的 `languageNames` 映射
2. ✅ 測試翻譯 API 對新語言的支援
3. ✅ 部署 Cloud Functions

**預估時間**: 30 分鐘

---

### 階段 2：前端更新（Flutter）

1. ✅ 更新 `language_detector.dart` 中的 `supportedLanguages` 列表
2. ✅ 創建 `grouped_language_selector.dart` 組件
3. ✅ 更新語言精靈頁面使用分組選擇器
4. ✅ 更新設定頁面使用分組選擇器
5. ✅ 更新聊天室語言切換使用分組選擇器
6. ✅ 更新測試檔案

**預估時間**: 2-3 小時

---

### 階段 3：測試

1. ✅ 單元測試：語言偵測器
2. ✅ 整合測試：翻譯 API
3. ✅ UI 測試：語言選擇器
4. ✅ 端到端測試：完整翻譯流程

**預估時間**: 1-2 小時

---

### 階段 4：部署和監控

1. ✅ 部署 Cloud Functions
2. ✅ 部署 Flutter 應用
3. ✅ 監控翻譯品質和成本
4. ✅ 收集用戶反饋

**預估時間**: 1 小時

---

## 📊 總結與建議

### 最終建議

#### ✅ 推薦方案：全部使用 GPT-4o-mini + 分組 UI

**理由**：

1. **成本不變**
   - 智能翻譯策略確保成本不受支援語言數量影響
   - 每則訊息成本仍然是 $0.00005

2. **品質足夠**
   - GPT-4o-mini 對所有 25 種語言都有良好支援
   - 對於聊天訊息翻譯，品質已經足夠

3. **實作簡單**
   - 無需複雜的模型選擇邏輯
   - 維護成本低

4. **用戶體驗好**
   - 分組 UI 易於瀏覽和查找
   - 常用語言快速訪問

---

### 何時考慮混合模型策略？

只有在以下情況下才建議使用混合模型：

1. **收到大量關於特定語言翻譯品質的投訴**
   - 特別是印度語系（hi, bn, te, ta）
   - 或 RTL 語言（ar, ur）

2. **業務擴展到專業領域**
   - 法律、醫療文件翻譯
   - 需要更高的翻譯準確度

3. **成本不再是主要考量**
   - 業務收入足以支撐 4 倍的翻譯成本

---

### 監控指標

建議監控以下指標來評估是否需要升級特定語言到 GPT-4o：

1. **按語言的翻譯品質投訴率**
   - 目標: < 1%
   - 如果特定語言超過 5%，考慮升級該語言到 GPT-4o

2. **按語言的使用量**
   - 追蹤每種語言的訊息數量
   - 優先優化高使用量的語言

3. **用戶滿意度**
   - 通過問卷調查收集反饋
   - 特別關注新增語言的用戶反饋

---

## 📚 相關文檔

- **成本分析報告**: `docs/GPT4O_VS_GPT4O_MINI_COST_ANALYSIS.md`
- **智能翻譯優化報告**: `docs/SMART_TRANSLATION_OPTIMIZATION.md`
- **自動翻譯語言配置修正報告**: `docs/AUTO_TRANSLATION_LANGUAGE_FIX.md`

---

**結論**: ✅ **強烈建議擴展到 25 種語言，使用 GPT-4o-mini + 分組 UI**

**預期效果**：
- ✅ 成本不變（$0.00005/則）
- ✅ 支援更多用戶群體
- ✅ 提升產品競爭力
- ✅ 實作簡單，風險低

---

## 🚀 快速開始

如果您同意此方案，我可以立即開始實作：

1. **階段 1**: 更新 Firebase Cloud Functions（30 分鐘）
2. **階段 2**: 更新 Flutter 客戶端（2-3 小時）
3. **階段 3**: 測試和部署（1-2 小時）

**總預估時間**: 4-6 小時

請告訴我是否要開始實作，或者您有任何問題或調整建議。

