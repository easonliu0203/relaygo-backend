# Firestore 同步測試指南

**目的**：驗證 Supabase → Firestore 同步是否正常工作  
**狀態**：✅ 所有修復已完成，待測試  
**預計時間**：10-15 分鐘

---

## 📋 快速開始

### 方法 1：手動測試（推薦）⭐

**適合**：第一次測試，需要詳細檢查每個步驟

**步驟**：
1. 閱讀 `完整驗證流程.md`
2. 按照步驟逐一執行
3. 記錄測試結果

**優點**：
- 可以詳細檢查每個環節
- 容易發現問題
- 適合診斷和學習

---

### 方法 2：自動化測試（快速）

**適合**：快速驗證，已經熟悉流程

#### Windows (PowerShell)

```powershell
# 設置環境變數（如果還沒有）
$env:SUPABASE_SERVICE_ROLE_KEY = "your-service-role-key"

# 執行測試
.\test-firestore-sync.ps1
```

#### Linux/Mac (Node.js)

```bash
# 安裝依賴
npm install node-fetch

# 設置環境變數
export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"

# 執行測試
node test-firestore-sync.js
```

**優點**：
- 快速（1-2 分鐘）
- 自動化
- 適合重複測試

---

## 🎯 測試重點

### 1. Edge Function 測試

**檢查項目**：
- ✅ 手動觸發返回 `success: 7, failure: 0`
- ✅ 日誌顯示認證成功
- ✅ 日誌顯示正確的欄位格式
- ✅ 日誌顯示寫入成功

**如何測試**：
1. 打開：https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
2. 點擊 sync-to-firestore → Invoke
3. 檢查回應和日誌

---

### 2. Firestore 資料測試（⭐ 最重要）

**檢查項目**：
- ✅ `orders_rt` 集合有訂單文檔
- ✅ `pickupLocation` 類型是 **geopoint**（不是 map）
- ✅ `dropoffLocation` 類型是 **geopoint**（不是 map）
- ✅ 有 `dropoffAddress` 欄位（不是 `destination`）
- ✅ 有 `bookingTime` 欄位（組合的時間）
- ✅ 有 `passengerCount`、`estimatedFare`、`depositPaid` 欄位

**如何測試**：
1. 打開：https://console.firebase.google.com
2. 選擇您的專案 → Firestore Database
3. 查看 `orders_rt` 集合
4. 點擊任一訂單文檔
5. 確認欄位類型和格式

**關鍵**：
- `pickupLocation` 和 `dropoffLocation` 必須顯示為 **geopoint**
- 如果顯示為 **map**，表示格式不正確

---

### 3. 客戶端 App 測試

**檢查項目**：
- ✅ 訂單列表顯示正常
- ✅ 訂單詳情顯示正常
- ✅ 不顯示「載入訂單失敗」
- ✅ 不顯示「訂單不存在」

**如何測試**：
1. 完全關閉並重新啟動 App
2. 登入測試帳號
3. 查看訂單列表
4. 點擊訂單查看詳情

---

## 📊 已完成的修復

### 修復 1：OAuth 2.0 認證 ✅

**問題**：使用 Web API Key 導致 401 錯誤  
**修復**：使用 Service Account 生成 OAuth 2.0 Token  
**文檔**：`修復完成-下一步操作.md`

### 修復 2：欄位映射 ✅

**問題**：欄位名稱不匹配（`destination` vs `dropoffAddress`）  
**修復**：更新欄位映射，匹配客戶端期望  
**文檔**：`docs/20251006_0023_06_Firestore欄位映射修復.md`

### 修復 3：GeoPoint 格式 ✅

**問題**：location 存儲為 Map 而不是 GeoPoint  
**修復**：使用正確的 GeoPoint 格式  
**文檔**：`docs/20251006_0840_07_GeoPoint格式修復.md`

---

## 🆘 故障排除

### 問題 A：Edge Function 失敗

**症狀**：`success: 0, failure: 7`

**診斷**：
1. 檢查 Edge Function 日誌
2. 查找錯誤訊息
3. 參考 `診斷_Firestore沒有資料.md`

**常見原因**：
- 環境變數未設置
- Service Account 格式錯誤
- 網路問題

---

### 問題 B：Firestore 格式不正確

**症狀**：`pickupLocation` 類型是 **map**，不是 **geopoint**

**診斷**：
1. 檢查是否是舊資料
2. 創建新訂單測試
3. 檢查 Edge Function 日誌

**解決**：
1. 手動觸發 Edge Function
2. 檢查新訂單的格式
3. 如果仍然是 map，檢查 Edge Function 代碼

---

### 問題 C：客戶端 App 顯示錯誤

**症狀**：「載入訂單失敗」或「訂單不存在」

**診斷**：
1. 檢查 Firestore 格式是否正確
2. 檢查客戶端緩存
3. 截圖錯誤訊息

**解決**：
1. 完全關閉並重新啟動 App
2. 創建新訂單測試
3. 如果仍然失敗，提供錯誤訊息

---

## 📚 文檔索引

### 測試文檔
- ✅ `README-測試指南.md` - 本文檔（測試指南）
- ✅ `完整驗證流程.md` - 詳細的手動測試步驟
- ✅ `test-firestore-sync.ps1` - PowerShell 自動化測試腳本
- ✅ `test-firestore-sync.js` - Node.js 自動化測試腳本

### 修復文檔
- ✅ `docs/20251006_0840_07_GeoPoint格式修復.md` - GeoPoint 格式修復 ⭐
- ✅ `docs/20251006_0023_06_Firestore欄位映射修復.md` - 欄位映射修復
- ✅ `修復完成-下一步操作.md` - OAuth 2.0 認證修復

### 快速測試指南
- ✅ `立即測試-GeoPoint修復.md` - GeoPoint 測試指南
- ✅ `立即測試-欄位映射修復.md` - 欄位映射測試指南

### 診斷工具
- ✅ `supabase/check-firestore-sync.sql` - SQL 診斷查詢
- ✅ `診斷_Firestore沒有資料.md` - 診斷指南

---

## 🎯 測試檢查清單

### 準備工作
- [ ] 已設置 `FIREBASE_SERVICE_ACCOUNT` 環境變數
- [ ] 已部署最新的 Edge Function
- [ ] 已閱讀測試文檔

### Edge Function 測試
- [ ] 手動觸發成功（success: 7）
- [ ] 日誌顯示認證成功
- [ ] 日誌顯示正確的欄位格式（`_latitude`, `_longitude`）
- [ ] 日誌顯示寫入成功

### Firestore 測試
- [ ] `orders_rt` 集合有訂單
- [ ] `pickupLocation` 類型是 **geopoint**
- [ ] `dropoffLocation` 類型是 **geopoint**
- [ ] 有 `dropoffAddress` 欄位
- [ ] 有 `bookingTime` 欄位
- [ ] 有 `passengerCount` 欄位

### 客戶端 App 測試
- [ ] 訂單列表顯示正常
- [ ] 訂單詳情顯示正常
- [ ] 不顯示錯誤訊息

---

## 💡 測試技巧

### 1. 從簡單到複雜

**順序**：
1. 先測試 Edge Function（最簡單）
2. 再測試 Firestore 資料（中等）
3. 最後測試客戶端 App（最複雜）

**原因**：
- 如果 Edge Function 失敗，後面的測試都會失敗
- 逐步排除問題，更容易診斷

---

### 2. 使用新資料測試

**建議**：
- 創建新訂單測試
- 不要只看舊訂單
- 舊訂單可能是舊格式

**原因**：
- 修復只影響新資料
- 舊資料可能需要手動修復

---

### 3. 檢查資料類型

**重點**：
- 在 Firebase Console 中檢查欄位類型
- 不只是檢查欄位是否存在
- 確認類型是否正確（geopoint vs map）

**原因**：
- 類型錯誤是最常見的問題
- 客戶端無法解析錯誤的類型

---

## 🚀 下一步

### 如果測試成功 ✅

1. **設置自動同步**
   - 確認 Cron Job 已設置（每 30 秒）
   - 測試自動同步是否正常

2. **監控和維護**
   - 定期檢查 Edge Function 日誌
   - 監控錯誤率
   - 如有問題及時修復

3. **優化和改進**
   - 考慮添加更多日誌
   - 改進錯誤處理
   - 添加單元測試

### 如果測試失敗 ❌

1. **記錄詳細資訊**
   - 哪個步驟失敗？
   - 具體的錯誤訊息？
   - 截圖錯誤畫面

2. **參考故障排除**
   - 查看 `完整驗證流程.md` 的故障排除部分
   - 查看 `診斷_Firestore沒有資料.md`

3. **尋求幫助**
   - 提供詳細的錯誤訊息
   - 提供 Edge Function 日誌
   - 提供 Firestore 資料截圖

---

**當前狀態**：✅ 所有修復已完成  
**測試狀態**：⏳ 待執行  
**預計時間**：10-15 分鐘

🚀 **請選擇一種測試方法並立即開始測試！**

