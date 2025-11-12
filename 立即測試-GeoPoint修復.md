# 立即測試：GeoPoint 格式修復

**問題**：客戶端 App 顯示「載入訂單失敗」  
**錯誤**：`type '_Map<String, dynamic>' is not a subtype of type 'GeoPoint'`  
**根本原因**：Edge Function 寫入的 location 格式不是 Firestore GeoPoint  
**修復**：已更新為正確的 GeoPoint 格式  
**狀態**：✅ 已部署，待測試

---

## 🎯 問題根源

### 錯誤訊息
```
載入訂單失敗
type '_Map<String, dynamic>' is not a subtype of type 'GeoPoint'
```

### 診斷
- 客戶端期望 `pickupLocation` 和 `dropoffLocation` 是 **Firestore GeoPoint** 類型
- 但 Edge Function 寫入的是 **普通 Map**：`{ latitude: 0, longitude: 0 }`
- Dart 無法將 Map 轉換為 GeoPoint，導致解析失敗

---

## 🔧 修復內容

### 修復前（錯誤）

**Edge Function 寫入**：
```typescript
pickupLocation: { latitude: 0, longitude: 0 },  // ❌ 普通 Map
dropoffLocation: { latitude: 0, longitude: 0 }, // ❌ 普通 Map
```

**Firestore 存儲**：
```
pickupLocation: map {
  latitude: 0,
  longitude: 0
}
```
- 類型：**map** ❌

**客戶端解析**：
```dart
pickupLocation: LocationPoint.fromGeoPoint(data['pickupLocation'])
// ❌ 錯誤：收到 Map，期望 GeoPoint
```

---

### 修復後（正確）

**Edge Function 寫入**：
```typescript
pickupLocation: {
  _latitude: 25.0330,   // ✅ GeoPoint 格式
  _longitude: 121.5654,
},
dropoffLocation: {
  _latitude: 25.0330,
  _longitude: 121.5654,
},
```

**轉換為 Firestore REST API 格式**：
```json
{
  "geoPointValue": {
    "latitude": 25.0330,
    "longitude": 121.5654
  }
}
```

**Firestore 存儲**：
```
pickupLocation: geopoint (25.033, 121.5654)
```
- 類型：**geopoint** ✅

**客戶端解析**：
```dart
pickupLocation: LocationPoint.fromGeoPoint(data['pickupLocation'])
// ✅ 成功：收到 GeoPoint
```

---

## 🚀 立即測試（5 分鐘）

### 步驟 1：手動觸發 Edge Function（1 分鐘）

1. **打開 Functions 頁面**
   ```
   https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
   ```

2. **點擊 sync-to-firestore → Invoke**

3. **預期結果**：
   ```json
   {
     "message": "事件處理完成",
     "total": 7,
     "success": 7,
     "failure": 0
   }
   ```

---

### 步驟 2：檢查 Edge Function 日誌（1 分鐘）

1. **點擊「Logs」標籤**

2. **查找以下訊息**：

   **應該看到**：
   ```
   轉換後的 Firestore 資料: {
     ...
     pickupLocation: { _latitude: 25.033, _longitude: 121.5654 },
     dropoffLocation: { _latitude: 25.033, _longitude: 121.5654 },
     ...
   }
   ✅ Firestore 文檔已更新
   ```

   **重點檢查**：
   - ✅ `pickupLocation` 有 `_latitude` 和 `_longitude`
   - ✅ `dropoffLocation` 有 `_latitude` 和 `_longitude`
   - 不應該只有 `latitude` 和 `longitude`（沒有底線）

---

### 步驟 3：檢查 Firestore 資料類型（1 分鐘）⭐ 重要

1. **打開 Firebase Console**
   ```
   https://console.firebase.google.com
   ```

2. **選擇您的專案 → Firestore Database**

3. **查看 `orders_rt` 集合**

4. **點擊任一訂單文檔**

5. **確認資料類型**：

   **正確的格式**：
   ```
   pickupLocation: geopoint (25.033, 121.5654)
   dropoffLocation: geopoint (25.033, 121.5654)
   ```
   - 類型顯示為 **geopoint** ✅
   - 不是 **map** ❌

   **如果看到錯誤的格式**：
   ```
   pickupLocation: map {
     latitude: 0,
     longitude: 0
   }
   ```
   - 類型顯示為 **map** ❌
   - 表示還是舊資料，需要重新同步

---

### 步驟 4：測試客戶端 App（2 分鐘）

1. **重新啟動客戶端 App**
   - 完全關閉 App
   - 重新打開（清除緩存）

2. **登入您的測試帳號**

3. **查看訂單列表**

4. **點擊任一訂單查看詳情**

5. **預期結果**：
   - ✅ 不再顯示「載入訂單失敗」
   - ✅ 不再顯示「訂單不存在」
   - ✅ 顯示訂單詳情（地點、時間、費用等）

---

## ✅ 驗證成功的標誌

### 1. Edge Function 日誌
```
轉換後的 Firestore 資料: {
  pickupLocation: { _latitude: 25.033, _longitude: 121.5654 },
  dropoffLocation: { _latitude: 25.033, _longitude: 121.5654 },
  ...
}
✅ Firestore 文檔已更新
```

### 2. Firestore 資料類型
```
pickupLocation: geopoint (25.033, 121.5654)  ✅
dropoffLocation: geopoint (25.033, 121.5654) ✅
```
- **不是** `map { latitude: 0, longitude: 0 }` ❌

### 3. 客戶端 App
- ✅ 訂單列表顯示正常
- ✅ 訂單詳情顯示正常
- ✅ 不再顯示「載入訂單失敗」
- ✅ 不再顯示「訂單不存在」

---

## 🆘 如果仍然失敗

### 問題 A：Firestore 中仍然是 map 類型

**可能原因**：
- 查看的是舊訂單
- 新訂單還沒有同步

**解決**：
1. 創建一個新訂單（從客戶端 App）
2. 等待 30 秒（Cron Job 執行）
3. 或手動觸發 Edge Function
4. 檢查新訂單的 Firestore 文檔
5. 確認類型是 **geopoint**，不是 **map**

---

### 問題 B：客戶端 App 仍然顯示錯誤

**可能原因**：
- 客戶端緩存
- 或查詢的是舊訂單

**解決**：
1. **完全關閉並重新啟動 App**（清除緩存）
2. 創建一個新訂單
3. 查看新訂單的詳情
4. 如果新訂單可以正常顯示，表示修復成功

---

### 問題 C：Edge Function 日誌沒有 `_latitude`

**可能原因**：
- Edge Function 沒有重新部署
- 或使用的是舊版本

**解決**：
1. 確認部署成功：https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
2. 查看 sync-to-firestore 的「Version」
3. 如果不是最新版本，重新部署：
   ```bash
   npx supabase functions deploy sync-to-firestore --project-ref vlyhwegpvpnjyocqmfqc
   ```

---

## 📊 修復前後對比

| 項目 | 修復前（錯誤） | 修復後（正確） |
|------|---------------|---------------|
| **Edge Function 寫入** | `{ latitude: 0, longitude: 0 }` | `{ _latitude: 25.033, _longitude: 121.5654 }` |
| **Firestore 類型** | **map** ❌ | **geopoint** ✅ |
| **REST API 格式** | `{ mapValue: {...} }` | `{ geoPointValue: {...} }` |
| **客戶端解析** | ❌ 失敗（類型錯誤） | ✅ 成功 |
| **App 顯示** | ❌ 載入訂單失敗 | ✅ 正常顯示 |

---

## 📋 檢查清單

- [ ] 手動觸發 Edge Function（success: 7）
- [ ] 檢查 Edge Function 日誌（看到 `_latitude` 和 `_longitude`）
- [ ] 檢查 Firestore 資料類型（確認是 **geopoint**，不是 **map**）⭐ 重要
- [ ] 重新啟動客戶端 App
- [ ] 測試訂單列表
- [ ] 測試訂單詳情
- [ ] 確認不再顯示「載入訂單失敗」

---

## 💡 關鍵要點

### 1. Firestore 資料類型很重要

**GeoPoint 的正確格式**：
- 在 Firestore 中必須是 **geopoint** 類型
- 不能是 **map** 類型
- 客戶端才能正確解析

### 2. 如何檢查資料類型

**在 Firebase Console 中**：
- 打開 Firestore → 點擊文檔
- 查看欄位旁邊的類型標籤
- 應該顯示 **geopoint**，不是 **map**

### 3. 如何修復舊資料

**如果舊訂單仍然是 map 類型**：
- 手動觸發 Edge Function 重新同步
- 或創建新訂單測試
- 舊訂單可能需要手動修復或忽略

---

## 📚 相關文檔

- `docs/20251006_0840_07_GeoPoint格式修復.md` - 完整開發歷程 ⭐
- `docs/20251006_0023_06_Firestore欄位映射修復.md` - 欄位映射修復
- `Firebase_Service_Account_設置指南.md` - Service Account 設置

---

**修復狀態**：✅ 完成並部署  
**測試狀態**：⏳ 待用戶驗證  
**預計時間**：5 分鐘

🚀 **請立即執行測試步驟，特別是步驟 3（檢查 Firestore 資料類型）！**

