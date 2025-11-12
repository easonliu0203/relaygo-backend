# Firestore 索引修復指南

**日期**: 2025-10-08  
**問題**: 取消訂單後出現 Firestore 索引缺失錯誤  
**狀態**: 🔧 需要創建索引

---

## 📋 問題分析

### 錯誤訊息
```
[cloud_firestore/failed-precondition] The query requires an index.
```

### 發生位置
1. **客戶端「我的訂單 > 進行中」頁面**
2. **客戶端「我的訂單 > 歷史訂單」頁面**
3. **公司端（管理後台）訂單頁面**

### 根本原因

#### 查詢代碼 (mobile/lib/core/services/booking_service.dart)

**進行中訂單查詢** (第 342-363 行):
```dart
Stream<List<BookingOrder>> getActiveBookings() {
  return _firestore
      .collection('orders_rt')
      .where('customerId', isEqualTo: currentUserId)  // 條件 1
      .where('status', whereIn: [                      // 條件 2 (whereIn)
        BookingStatus.pending.name,
        BookingStatus.matched.name,
        BookingStatus.inProgress.name,
      ])
      .orderBy('createdAt', descending: true)          // 排序
      .snapshots()
      ...
}
```

**需要的索引**: `customerId` + `status` + `createdAt`

#### 為什麼之前沒問題?

1. **之前可能沒有 `cancelled` 狀態的訂單**
   - 查詢只涉及 `pending`, `matched`, `inProgress`
   - Firestore 可能使用了部分索引

2. **取消訂單後**
   - 訂單狀態變為 `cancelled`
   - 歷史訂單查詢開始包含 `cancelled` 狀態
   - 觸發了需要完整複合索引的查詢

3. **現有索引不足**
   - ✅ 有: `customerId` + `createdAt`
   - ✅ 有: `status` + `createdAt`
   - ❌ 缺少: `customerId` + `status` + `createdAt`

---

## ✅ 解決方案

### 方案 1: 使用 Firebase Console (推薦) ⭐

#### 步驟 1: 點擊錯誤連結

錯誤訊息中包含一個 URL,點擊它會自動打開 Firebase Console 並預填索引配置。

**錯誤 URL 示例**:
```
https://console.firebase.google.com/v1/r/project/ride-platform-f1676/firestore/indexes?create_composite=...
```

#### 步驟 2: 確認索引配置

Firebase Console 會顯示需要創建的索引:

```
Collection ID: orders_rt
Fields indexed:
  - customerId (Ascending)
  - status (Ascending)
  - createdAt (Descending)
Query scope: Collection
```

#### 步驟 3: 點擊「Create Index」

點擊按鈕創建索引。

#### 步驟 4: 等待索引建立

- 索引建立需要幾分鐘時間
- 狀態會從「Building」變為「Enabled」
- 建立完成後,查詢就能正常工作

---

### 方案 2: 使用 Firebase CLI

#### 步驟 1: 確認索引文件已更新

檢查 `firebase/firestore.indexes.json`:

```json
{
  "indexes": [
    ...
    {
      "collectionGroup": "orders_rt",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "customerId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    ...
  ]
}
```

#### 步驟 2: 部署索引

```bash
# 安裝 Firebase CLI (如果還沒安裝)
npm install -g firebase-tools

# 登入 Firebase
firebase login

# 部署索引
firebase deploy --only firestore:indexes
```

#### 步驟 3: 等待索引建立

```bash
# 查看索引狀態
firebase firestore:indexes
```

---

### 方案 3: 手動在 Firebase Console 創建

#### 步驟 1: 打開 Firebase Console

1. 前往: https://console.firebase.google.com
2. 選擇專案: `ride-platform-f1676`
3. 點擊左側選單的「Firestore Database」
4. 點擊「Indexes」標籤

#### 步驟 2: 創建複合索引

1. 點擊「Create Index」
2. 填寫以下資訊:

```
Collection ID: orders_rt

Fields:
  Field 1: customerId    | Order: Ascending
  Field 2: status        | Order: Ascending
  Field 3: createdAt     | Order: Descending

Query scope: Collection
```

3. 點擊「Create」

#### 步驟 3: 等待建立完成

- 索引狀態會顯示「Building」
- 等待幾分鐘直到狀態變為「Enabled」

---

## 🧪 驗證修復

### 測試步驟

#### 1. 等待索引建立完成

在 Firebase Console 的 Indexes 頁面確認:
- ✅ 索引狀態為「Enabled」
- ✅ 沒有錯誤訊息

#### 2. 測試「進行中」頁面

1. 打開 Flutter 應用
2. 進入「我的訂單」
3. 切換到「進行中」標籤

**預期結果**:
- ✅ 頁面正常載入
- ✅ 顯示進行中的訂單列表
- ✅ 不出現索引錯誤

#### 3. 測試「歷史訂單」頁面

1. 切換到「歷史訂單」標籤

**預期結果**:
- ✅ 頁面正常載入
- ✅ 顯示已完成和已取消的訂單
- ✅ 不出現索引錯誤

#### 4. 測試管理後台

1. 打開管理後台
2. 進入訂單管理頁面

**預期結果**:
- ✅ 訂單列表正常顯示
- ✅ 可以篩選不同狀態的訂單

---

## 📊 需要創建的索引列表

### orders_rt 集合

| 索引名稱 | 欄位 | 用途 |
|---------|------|------|
| customerId + createdAt | customerId (ASC)<br>createdAt (DESC) | ✅ 已存在<br>用於: 所有訂單列表 |
| status + createdAt | status (ASC)<br>createdAt (DESC) | ✅ 已存在<br>用於: 按狀態篩選 |
| **customerId + status + createdAt** | **customerId (ASC)**<br>**status (ASC)**<br>**createdAt (DESC)** | **❌ 需要創建**<br>**用於: 進行中/歷史訂單** |

### bookings 集合 (如果管理後台也有問題)

可能也需要相同的索引:

```json
{
  "collectionGroup": "bookings",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "customerId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

---

## 🔍 故障排除

### 問題 1: 索引建立失敗

**症狀**: 索引狀態顯示「Error」

**可能原因**:
- 欄位名稱錯誤
- 集合名稱錯誤
- Firebase 配額限制

**解決方法**:
1. 檢查欄位名稱是否正確 (customerId, status, createdAt)
2. 檢查集合名稱是否正確 (orders_rt)
3. 刪除錯誤的索引,重新創建

### 問題 2: 索引建立很慢

**症狀**: 索引一直顯示「Building」

**原因**: 
- 如果集合中有大量文檔,索引建立需要更長時間
- 正常情況下幾分鐘到幾小時不等

**解決方法**:
- 耐心等待
- 可以先使用其他功能
- 索引建立完成後會自動生效

### 問題 3: 仍然出現索引錯誤

**症狀**: 創建索引後仍然報錯

**可能原因**:
- 索引還在建立中
- 應用緩存了舊的錯誤
- 創建了錯誤的索引

**解決方法**:
```bash
# 1. 確認索引狀態
firebase firestore:indexes

# 2. 重啟應用
cd mobile
flutter clean
flutter run --flavor customer --target lib/apps/customer/main_customer.dart

# 3. 檢查索引配置是否正確
```

---

## 📚 技術說明

### 為什麼需要複合索引?

Firestore 的查詢規則:
1. **單一欄位查詢** - 不需要索引
2. **多欄位等值查詢** - 不需要索引
3. **包含 `whereIn` 或 `orderBy` 的查詢** - 需要複合索引

我們的查詢:
```dart
.where('customerId', isEqualTo: ...)  // 等值查詢
.where('status', whereIn: [...])      // whereIn 查詢 ← 需要索引
.orderBy('createdAt', ...)            // 排序 ← 需要索引
```

### 索引欄位順序

Firestore 複合索引的欄位順序很重要:
1. **等值查詢欄位** (`customerId`) - 放在前面
2. **範圍查詢欄位** (`status` with `whereIn`) - 放在中間
3. **排序欄位** (`createdAt`) - 放在最後

---

## ✅ 完成檢查清單

- [ ] 點擊錯誤 URL 或手動創建索引
- [ ] 確認索引配置正確
  - [ ] Collection: orders_rt
  - [ ] Fields: customerId (ASC), status (ASC), createdAt (DESC)
- [ ] 等待索引建立完成 (狀態: Enabled)
- [ ] 測試「進行中」頁面
- [ ] 測試「歷史訂單」頁面
- [ ] 測試管理後台 (如果適用)
- [ ] 確認所有頁面正常載入

---

## 🎯 預期結果

完成索引創建後:
- ✅ 「我的訂單 > 進行中」頁面正常顯示
- ✅ 「我的訂單 > 歷史訂單」頁面正常顯示
- ✅ 管理後台訂單頁面正常顯示
- ✅ 不再出現索引缺失錯誤
- ✅ 查詢性能提升

---

## 📞 需要幫助?

如果遇到問題:
1. 檢查 Firebase Console 的索引狀態
2. 查看應用的控制台日誌
3. 確認索引配置與查詢匹配

