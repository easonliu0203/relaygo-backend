# 立即測試：Firestore 雙寫策略

**問題**：Firestore `bookings` 集合沒有新訂單  
**根本原因**：Edge Function 只寫入 `orders_rt` 集合  
**修復**：實施雙寫策略，同時寫入 `orders_rt` 和 `bookings`  
**狀態**：✅ 已部署，待測試

---

## 🎯 修復內容

### 修復前（錯誤）❌

```
Edge Function 同步流程:
Supabase bookings 表
    ↓
Outbox 事件
    ↓
Edge Function
    ↓
Firestore orders_rt 集合  ✅ 有資料
    ↓
Firestore bookings 集合   ❌ 沒有資料（未寫入）
```

---

### 修復後（正確）✅

```
Edge Function 同步流程（雙寫）:
Supabase bookings 表
    ↓
Outbox 事件
    ↓
Edge Function
    ├─→ Firestore orders_rt 集合  ✅ 有資料
    └─→ Firestore bookings 集合   ✅ 有資料（新增）
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

   **應該看到（雙寫成功）**：
   ```
   準備更新 Firestore（雙寫）: orders_rt/{bookingId} 和 bookings/{bookingId}
   ✅ Firestore 文檔已更新: orders_rt/{bookingId}
   ✅ Firestore 文檔已更新: bookings/{bookingId}
   ✅ 雙寫成功: orders_rt/{bookingId} 和 bookings/{bookingId}
   ```

   **不應該看到**：
   ```
   ❌ 所有集合更新失敗
   ❌ Firestore 更新失敗
   ```

---

### 步驟 3：檢查 Firestore 資料（2 分鐘）⭐ 最重要

#### 3.1 打開 Firebase Console

1. **打開 Firebase Console**
   ```
   https://console.firebase.google.com
   ```

2. **選擇專案 → Firestore Database**

---

#### 3.2 檢查 `orders_rt` 集合

1. **點擊 `orders_rt` 集合**

2. **確認有訂單文檔**

3. **點擊任一訂單，記下文檔 ID**
   - 例如：`550e8400-e29b-41d4-a716-446655440000`

4. **確認資料格式正確**：
   ```
   customerId: "hUu4fH5dTlW9VUYm6GojXvRLdni2"
   status: "pending"
   pickupLocation: [25.033° N, 121.5654° E]  ← geopoint
   dropoffLocation: [25.033° N, 121.5654° E] ← geopoint
   bookingTime: October 6, 2025 at 2:09:00 PM ← timestamp
   passengerCount: 1                          ← integer
   ...
   ```

---

#### 3.3 檢查 `bookings` 集合 ⭐ 重點

1. **點擊 `bookings` 集合**

2. **確認有訂單文檔**
   - ✅ 應該有與 `orders_rt` 相同的訂單
   - ✅ 文檔 ID 應該相同

3. **點擊相同 ID 的訂單**
   - 例如：`550e8400-e29b-41d4-a716-446655440000`

4. **確認資料格式一致**：
   ```
   customerId: "hUu4fH5dTlW9VUYm6GojXvRLdni2"  ✅ 相同
   status: "pending"                          ✅ 相同
   pickupLocation: [25.033° N, 121.5654° E]  ✅ 相同
   dropoffLocation: [25.033° N, 121.5654° E] ✅ 相同
   bookingTime: October 6, 2025 at 2:09:00 PM ✅ 相同
   passengerCount: 1                          ✅ 相同
   ...
   ```

---

#### 3.4 對比兩個集合

**正確的狀態**：
```
orders_rt 集合:
  - 550e8400-e29b-41d4-a716-446655440000  ✅
  - 661f9511-f3ac-52e5-b827-557766551111  ✅
  - ...

bookings 集合:
  - 550e8400-e29b-41d4-a716-446655440000  ✅ 相同 ID
  - 661f9511-f3ac-52e5-b827-557766551111  ✅ 相同 ID
  - ...

兩個集合的訂單數量應該相同
兩個集合的資料內容應該一致
```

---

### 步驟 4：測試客戶端 App（1 分鐘）

1. **重新啟動 App**（如果正在運行）

2. **查看訂單列表**

3. **點擊訂單查看詳情**

4. **預期結果**：
   - ✅ 訂單列表顯示正常
   - ✅ 訂單詳情顯示正常
   - ✅ 不顯示任何錯誤

---

## ✅ 驗證成功的標誌

### 1. Edge Function 日誌

**正確的日誌**：
```
準備更新 Firestore（雙寫）: orders_rt/{bookingId} 和 bookings/{bookingId}
✅ Firestore 文檔已更新: orders_rt/{bookingId}
✅ Firestore 文檔已更新: bookings/{bookingId}
✅ 雙寫成功: orders_rt/{bookingId} 和 bookings/{bookingId}
```

**不應該看到**：
```
❌ 所有集合更新失敗
❌ Firestore 更新失敗
⚠️ 雙寫部分成功（表示一個成功一個失敗）
```

---

### 2. Firestore 資料

**orders_rt 集合**：
```
✅ 有訂單文檔
✅ 資料格式正確（GeoPoint、Timestamp、Integer）
```

**bookings 集合**：
```
✅ 有訂單文檔（與 orders_rt 相同）
✅ 文檔 ID 相同
✅ 資料格式一致
✅ 訂單數量相同
```

---

### 3. 客戶端 App

```
✅ 訂單列表顯示正常
✅ 訂單詳情顯示正常
✅ 不顯示任何錯誤
```

---

## 🆘 如果驗證失敗

### 問題 A：Edge Function 日誌顯示「部分成功」

**症狀**：
```
⚠️ 雙寫部分成功: 成功 [orders_rt], 失敗 [bookings]
```

**可能原因**：
- `bookings` 集合的權限問題
- Firestore 規則配置問題
- 網路問題

**解決**：
1. 檢查 Edge Function 日誌中的詳細錯誤訊息
2. 確認 Service Account 有寫入 `bookings` 集合的權限
3. 檢查 `firebase/firestore.rules` 配置
4. 重新觸發 Edge Function

---

### 問題 B：`bookings` 集合仍然沒有資料

**可能原因**：
- Edge Function 沒有重新部署
- 使用的是舊版本的 Edge Function
- 查看的是舊訂單

**解決**：
1. **確認部署成功**：
   - 打開：https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
   - 查看 sync-to-firestore 的「Version」
   - 確認是最新版本

2. **創建新訂單測試**：
   - 從客戶端 App 創建新訂單
   - 等待 30 秒（Cron Job 執行）
   - 或手動觸發 Edge Function
   - 檢查新訂單是否在 `bookings` 集合中

3. **檢查 Edge Function 日誌**：
   - 確認有「雙寫」相關的日誌
   - 如果沒有，表示使用的是舊版本

---

### 問題 C：兩個集合的資料不一致

**可能原因**：
- 部分失敗（一個成功一個失敗）
- 資料格式轉換問題

**解決**：
1. **檢查 Edge Function 日誌**：
   - 查找「部分成功」的警告
   - 確認哪個集合失敗

2. **手動修復不一致的資料**：
   - 找出不一致的訂單
   - 從成功的集合複製到失敗的集合

3. **重新觸發同步**：
   - 手動觸發 Edge Function
   - 確認資料一致

---

## 📊 修復前後對比

| 項目 | 修復前（錯誤） | 修復後（正確） |
|------|---------------|---------------|
| **Edge Function 邏輯** | ❌ 單寫（只寫 orders_rt） | ✅ 雙寫（orders_rt + bookings） |
| **orders_rt 集合** | ✅ 有資料 | ✅ 有資料 |
| **bookings 集合** | ❌ 沒有資料 | ✅ 有資料 |
| **資料一致性** | ❌ 不一致 | ✅ 一致 |
| **日誌訊息** | `✅ Firestore 文檔已更新: orders_rt/{id}` | `✅ 雙寫成功: orders_rt/{id} 和 bookings/{id}` |

---

## 📋 檢查清單

- [ ] 手動觸發 Edge Function（success: 7）
- [ ] 檢查 Edge Function 日誌（看到「雙寫成功」）
- [ ] 檢查 `orders_rt` 集合（有訂單）
- [ ] 檢查 `bookings` 集合（有訂單）⭐ 重點
- [ ] 確認兩個集合的文檔 ID 相同
- [ ] 確認兩個集合的資料內容一致
- [ ] 測試客戶端 App（訂單顯示正常）

---

## 💡 關鍵要點

### 1. 雙寫策略的優點

**資料冗餘**：
- `orders_rt`：客戶端即時訂單（用於 App 顯示）
- `bookings`：完整訂單記錄（用於歷史查詢、報表、管理後台）

**分離關注點**：
- 不同用途使用不同集合
- 提高查詢效能

---

### 2. 容錯機制

**部分失敗處理**：
- 如果兩個都失敗 → 拋出錯誤，觸發重試
- 如果只有一個失敗 → 記錄警告，但不影響整體流程

**為什麼這樣設計？**
- 確保至少有一個集合有資料
- 避免因為一個集合失敗而影響整體流程

---

### 3. 如何檢查資料一致性

**步驟**：
1. 在 `orders_rt` 集合中找一個訂單 ID
2. 在 `bookings` 集合中找相同 ID 的訂單
3. 對比兩個訂單的資料內容
4. 確認完全一致

---

## 📚 相關文檔

- `docs/20251007_0022_11_Firestore雙寫策略實施.md` - 完整開發歷程 ⭐
- `docs/20251006_2254_10_BookingStatus_color屬性錯誤修復.md` - BookingStatus color 修復
- `修復總結-所有問題已解決.md` - 所有修復總結

---

## 🔄 後續步驟

### 1. 補寫歷史資料（可選）

**問題**：修復前的訂單只在 `orders_rt` 集合中

**解決**：
- 需要手動將 `orders_rt` 中的歷史訂單複製到 `bookings` 集合
- 或等待訂單更新時自動同步

---

### 2. 監控雙寫狀態

**建議**：
- 定期檢查 Edge Function 日誌
- 確認沒有「部分成功」的警告
- 確認兩個集合的訂單數量一致

---

**修復狀態**：✅ 完成並部署  
**測試狀態**：⏳ 待用戶驗證  
**預計時間**：5 分鐘

🚀 **請立即執行測試步驟，確認 `bookings` 集合有新訂單！**

