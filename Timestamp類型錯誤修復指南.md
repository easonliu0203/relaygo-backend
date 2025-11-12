# 🔧 Timestamp 類型錯誤修復指南

**日期**: 2025-10-09  
**問題**: `type 'String' is not a subtype of type 'Timestamp' in type cast`  
**狀態**: ✅ 已修復

---

## 📋 問題描述

### 錯誤訊息
```
載入失敗
type 'String' is not a subtype of type 'Timestamp' in type cast
```

### 發生位置
- 客戶端「我的訂單 > 進行中」標籤頁
- 客戶端「我的訂單 > 歷史訂單」標籤頁

### 症狀
- 頁面無法正常載入訂單列表
- 出現類型轉換錯誤

---

## 🔍 根本原因分析

### 問題根源

1. **Firestore 資料格式不一致**
   - **舊資料**: 時間戳存儲為 `String` 格式 (例如: `"2025-10-06T05:12:00"`)
   - **新資料**: 時間戳存儲為 `Firestore Timestamp` 格式 (正確)

2. **Flutter 代碼不兼容**
   - `BookingOrder.fromFirestore()` 方法直接進行類型轉換
   - 代碼: `(data['bookingTime'] as Timestamp).toDate()`
   - 遇到 String 格式時拋出錯誤

3. **歷史背景**
   - 舊版 Edge Function 將時間戳存儲為 String
   - 新版 Edge Function 已修復 (使用 `{ _timestamp: "..." }` 格式)
   - 但舊資料仍然是 String 格式,未遷移

### 影響範圍

**受影響的欄位**:
- `bookingTime` - 預約時間
- `createdAt` - 創建時間
- `matchedAt` - 配對時間 (可選)
- `completedAt` - 完成時間 (可選)

**受影響的集合**:
- `orders_rt` - 客戶端即時訂單
- `bookings` - 完整訂單記錄

---

## ✅ 解決方案

### 方案概述

採用 **混合方案**,確保向後兼容:

1. ✅ **修改 Flutter 代碼** - 支持兩種格式 (String 和 Timestamp)
2. ✅ **提供遷移腳本** - 將舊資料轉換為正確格式
3. ✅ **提供驗證腳本** - 檢查資料格式是否正確

### 優點

- ✅ **立即修復**: Flutter 代碼修改後,應用立即可用
- ✅ **向後兼容**: 支持舊資料,不會因為資料格式導致錯誤
- ✅ **漸進遷移**: 可以選擇性地遷移舊資料
- ✅ **未來保障**: 新資料使用正確格式

---

## 🔧 修復步驟

### 步驟 1: 修改 Flutter 代碼 ✅ 已完成

**文件**: `mobile/lib/core/models/booking_order.dart`

**修改內容**:

1. 添加輔助函數 `_parseTimestamp()` 和 `_parseOptionalTimestamp()`
2. 更新 `fromFirestore()` 方法使用這些函數

**關鍵代碼**:

```dart
/// 解析時間戳 - 支持 Timestamp 和 String 兩種格式
static DateTime _parseTimestamp(dynamic value) {
  if (value == null) {
    throw ArgumentError('Timestamp cannot be null');
  }
  
  // 處理 Firestore Timestamp 格式 (正確格式)
  if (value is Timestamp) {
    return value.toDate();
  }
  
  // 處理 String 格式 (舊資料兼容)
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      throw ArgumentError('Invalid timestamp string format: $value');
    }
  }
  
  throw ArgumentError('Invalid timestamp format: ${value.runtimeType}');
}

/// 解析可選的時間戳 - 支持 null 值
static DateTime? _parseOptionalTimestamp(dynamic value) {
  if (value == null) return null;
  return _parseTimestamp(value);
}
```

**使用方式**:

```dart
factory BookingOrder.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  
  return BookingOrder(
    ...
    bookingTime: _parseTimestamp(data['bookingTime']),
    createdAt: _parseTimestamp(data['createdAt']),
    matchedAt: _parseOptionalTimestamp(data['matchedAt']),
    completedAt: _parseOptionalTimestamp(data['completedAt']),
  );
}
```

---

### 步驟 2: 驗證 Firestore 資料格式 (可選)

**目的**: 檢查 Firestore 中有多少文檔需要遷移

**腳本**: `firebase/verify-timestamp-fields.js`

**使用方法**:

```bash
# 1. 安裝依賴
cd firebase
npm install firebase-admin

# 2. 設置 Firebase 憑證
# 方式 A: 使用服務帳號金鑰
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"

# 方式 B: 使用 gcloud CLI (如果已登入)
gcloud auth application-default login

# 3. 運行驗證腳本
node verify-timestamp-fields.js
```

**輸出示例**:

```
╔════════════════════════════════════════╗
║  Firestore 時間戳欄位驗證腳本          ║
╚════════════════════════════════════════╝

📋 檢查計劃:
  集合: orders_rt, bookings
  欄位: bookingTime, createdAt, matchedAt, completedAt

========================================
檢查集合: orders_rt
========================================

📊 總文檔數: 15

📊 欄位類型統計:

bookingTime:
  ✅ Timestamp: 10
  ⚠️  String (valid): 5
  ❌ String (invalid): 0
  ⏭️  null: 0
  ❓ other: 0

createdAt:
  ✅ Timestamp: 10
  ⚠️  String (valid): 5
  ❌ String (invalid): 0
  ⏭️  null: 0
  ❓ other: 0

⚠️  發現 10 個問題

========================================

總計:
  總文檔數: 15
  總問題數: 10

⚠️  發現問題! 需要運行遷移腳本修復

執行以下命令進行修復:
  node firebase/migrate-timestamp-fields.js
```

---

### 步驟 3: 遷移 Firestore 資料 (可選,推薦)

**目的**: 將舊資料轉換為正確的 Timestamp 格式

**腳本**: `firebase/migrate-timestamp-fields.js`

**使用方法**:

```bash
# 1. 確認已安裝依賴和設置憑證 (同步驟 2)

# 2. 運行遷移腳本
node migrate-timestamp-fields.js
```

**輸出示例**:

```
╔════════════════════════════════════════╗
║  Firestore 時間戳欄位遷移腳本          ║
╚════════════════════════════════════════╝

📋 遷移計劃:
  集合: orders_rt, bookings
  欄位: bookingTime, createdAt, matchedAt, completedAt
  操作: String → Firestore Timestamp

⚠️  警告: 此操作將修改 Firestore 資料
請確認您已備份資料並了解操作風險

========================================
開始遷移集合: orders_rt
========================================

📊 總文檔數: 15

處理批次 1/2 (文檔 1-10)
----------------------------------------
  🔄 bookingTime: "2025-10-06T05:12:00" → Timestamp
  🔄 createdAt: "2025-10-06T05:10:00" → Timestamp
  ✅ 已更新: orders_rt/abc123
  ...

========================================
集合 orders_rt 遷移完成
========================================
📊 統計:
  總文檔數: 15
  ✅ 已更新: 5
  ⏭️  已跳過: 10
  ❌ 失敗: 0
========================================

🎉 遷移成功! 所有時間戳欄位都已轉換為正確格式
```

---

### 步驟 4: 測試應用

**重新建置應用**:

```bash
cd mobile
flutter clean
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

**測試步驟**:

1. **測試「進行中」頁面**
   ```
   1. 打開應用
   2. 進入「我的訂單」
   3. 切換到「進行中」標籤
   ```
   
   **預期結果**:
   - ✅ 頁面正常載入
   - ✅ 顯示進行中的訂單列表
   - ✅ 不出現類型錯誤

2. **測試「歷史訂單」頁面**
   ```
   1. 切換到「歷史訂單」標籤
   ```
   
   **預期結果**:
   - ✅ 頁面正常載入
   - ✅ 顯示所有訂單 (包括已取消的)
   - ✅ 不出現類型錯誤

3. **測試新訂單創建**
   ```
   1. 創建新訂單
   2. 完成支付
   3. 查看訂單詳情
   ```
   
   **預期結果**:
   - ✅ 訂單正常創建
   - ✅ 時間戳正確顯示
   - ✅ 不出現類型錯誤

---

## 📊 技術說明

### 為什麼會有兩種格式?

**歷史演進**:

1. **舊版 Edge Function** (已棄用)
   ```typescript
   const firestoreData = {
     bookingTime: "2025-10-06T05:12:00",  // ❌ String 格式
     createdAt: "2025-10-06T05:10:00",    // ❌ String 格式
   }
   ```

2. **新版 Edge Function** (當前版本)
   ```typescript
   const firestoreData = {
     bookingTime: {
       _timestamp: "2025-10-06T05:12:00",  // ✅ 使用 _timestamp 標記
     },
     createdAt: {
       _timestamp: "2025-10-06T05:10:00",  // ✅ 使用 _timestamp 標記
     },
   }
   
   // convertToFirestoreFields 會轉換為:
   {
     bookingTime: { timestampValue: "2025-10-06T05:12:00Z" },  // ✅ Firestore Timestamp
     createdAt: { timestampValue: "2025-10-06T05:10:00Z" },    // ✅ Firestore Timestamp
   }
   ```

### 為什麼 Flutter 代碼需要支持兩種格式?

1. **舊資料未遷移**: Firestore 中仍有 String 格式的時間戳
2. **向後兼容**: 確保應用在遷移期間仍然可用
3. **漸進遷移**: 可以選擇性地遷移資料,不影響業務

### Firestore Timestamp 格式

**正確格式** (Firestore REST API):
```json
{
  "fields": {
    "createdAt": {
      "timestampValue": "2025-10-06T05:10:00Z"
    }
  }
}
```

**Flutter 讀取**:
```dart
final timestamp = data['createdAt'] as Timestamp;
final dateTime = timestamp.toDate();
```

---

## 🔍 故障排除

### 問題 1: 仍然出現類型錯誤

**症狀**: 修改代碼後仍然報錯

**可能原因**:
- Flutter 代碼未正確更新
- 應用緩存了舊代碼

**解決方法**:
```bash
cd mobile
flutter clean
rm -rf build/
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 問題 2: 遷移腳本執行失敗

**症狀**: `Error: Could not load the default credentials`

**原因**: Firebase 憑證未設置

**解決方法**:
```bash
# 方式 A: 使用服務帳號金鑰
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"

# 方式 B: 使用 gcloud CLI
gcloud auth application-default login
```

### 問題 3: 驗證腳本顯示仍有問題

**症狀**: 遷移後驗證腳本仍顯示 String 格式

**可能原因**:
- 遷移腳本執行失敗
- 有新資料在遷移後創建 (使用舊版 Edge Function)

**解決方法**:
1. 檢查 Edge Function 是否已更新到最新版本
2. 重新運行遷移腳本
3. 檢查遷移腳本的錯誤日誌

---

## ✅ 成功標準

### Flutter 代碼
- ✅ `_parseTimestamp()` 函數正確處理 Timestamp 和 String
- ✅ `_parseOptionalTimestamp()` 函數正確處理 null 值
- ✅ `fromFirestore()` 方法使用輔助函數

### Firestore 資料
- ✅ 所有時間戳欄位都是 Firestore Timestamp 格式
- ✅ 驗證腳本不報告任何問題

### 應用功能
- ✅ 「進行中」頁面正常載入
- ✅ 「歷史訂單」頁面正常載入
- ✅ 新訂單創建正常
- ✅ 不出現類型錯誤

---

## 📚 相關文檔

| 文檔 | 說明 |
|------|------|
| `docs/20251006_2047_08_Timestamp格式修復.md` | Edge Function 時間戳修復歷史 |
| `firebase/migrate-timestamp-fields.js` | Firestore 資料遷移腳本 |
| `firebase/verify-timestamp-fields.js` | Firestore 資料驗證腳本 |
| `mobile/lib/core/models/booking_order.dart` | BookingOrder 模型定義 |

---

## 🎉 完成後的效果

1. **應用立即可用**
   - 不再出現類型錯誤
   - 訂單列表正常顯示
   - 支持舊資料和新資料

2. **資料格式統一** (遷移後)
   - 所有時間戳都是 Firestore Timestamp 格式
   - 提升查詢性能
   - 減少代碼複雜度

3. **未來保障**
   - 新資料使用正確格式
   - 代碼向後兼容
   - 易於維護

---

## 📞 需要幫助?

1. **查看錯誤日誌**: 檢查 Flutter 控制台的詳細錯誤訊息
2. **運行驗證腳本**: 確認 Firestore 資料格式
3. **檢查 Edge Function**: 確認使用最新版本
4. **查看相關文檔**: 了解歷史修復記錄

