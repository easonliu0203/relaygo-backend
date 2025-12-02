# Driver 記錄自動生成功能實作文檔

## 📋 實作日期
2025-12-02

---

## 🎯 功能目標

在司機端 Mobile App 的車輛管理頁面實作自動生成 `drivers` 表記錄的功能。

---

## 📊 實作方案

採用 **方案 3（首次進入車輛管理頁面時自動生成）**

### 核心邏輯
```
用戶進入車輛管理頁面 
  ↓
檢查 drivers 表是否有記錄
  ↓
沒有 → 自動生成（is_available = FALSE）
有 → 返回現有記錄
```

---

## 🔧 修改的檔案

### Backend（3 個檔案）

#### 1. `backend/src/routes/drivers.ts`（新建）
- **功能**：提供 `POST /api/drivers/ensure` API 端點
- **邏輯**：
  1. 根據 `firebaseUid` 查找 Supabase `user_id`
  2. 檢查 `drivers` 表中是否已有記錄
  3. 如果已存在，返回現有記錄
  4. 如果不存在，創建新記錄（`is_available = FALSE`）
- **冪等性**：多次調用不會產生重複記錄

#### 2. `backend/src/minimal-server.ts`（修改）
- **修改內容**：
  - 添加 `import driversRoutes from './routes/drivers';`
  - 註冊路由：`app.use('/api/drivers', driversRoutes);`

---

### Mobile App（3 個檔案）

#### 3. `mobile/lib/core/models/driver.dart`（新建）
- **功能**：Driver 模型類
- **欄位**：對應 Supabase `drivers` 表的所有欄位
- **方法**：
  - `fromJson()`: 從 JSON 創建 Driver 實例
  - `toJson()`: 轉換為 JSON
  - `copyWith()`: 複製並修改部分欄位

#### 4. `mobile/lib/core/services/driver_service.dart`（新建）
- **功能**：Driver 服務類
- **方法**：
  - `ensureDriverRecord(String firebaseUid)`: 確保 drivers 表中存在記錄
- **API 調用**：`POST https://api.relaygo.pro/api/drivers/ensure`

#### 5. `mobile/lib/apps/driver/presentation/pages/vehicle_management_page.dart`（修改）
- **修改內容**：
  - 添加 `import '../../../../core/services/driver_service.dart';`
  - 添加 `final DriverService _driverService = DriverService();`
  - 在 `initState()` 中調用 `_ensureDriverRecord();`
  - 添加 `_ensureDriverRecord()` 方法

---

## 🔑 關鍵實作細節

### 1. 默認值設置
創建新 driver 記錄時的默認值：
```typescript
{
  user_id: userId,
  is_available: false,        // ⚠️ 重要：默認為 FALSE，需要人工審核
  rating: 0,
  total_trips: 0,
  total_reviews: 0,
  average_rating: 0,
  background_check_status: 'pending',
}
```

### 2. 冪等性保證
- Backend 使用 `SELECT` 檢查記錄是否存在
- 如果存在，直接返回現有記錄
- 如果不存在，才執行 `INSERT`
- 多次調用不會產生重複記錄

### 3. 錯誤處理
- 用戶未登入：返回並記錄警告
- 用戶不存在：返回 404 錯誤
- API 調用失敗：記錄錯誤並返回 null
- 網絡錯誤：捕獲異常並記錄

---

## 📝 API 規格

### POST /api/drivers/ensure

#### Request
```json
{
  "firebaseUid": "string"
}
```

#### Response (Success - 200)
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "userId": "uuid",
    "licenseNumber": null,
    "licenseExpiry": null,
    "vehicleType": null,
    "vehicleModel": null,
    "vehicleYear": null,
    "vehiclePlate": null,
    "insuranceNumber": null,
    "insuranceExpiry": null,
    "backgroundCheckStatus": "pending",
    "backgroundCheckDate": null,
    "rating": 0,
    "totalTrips": 0,
    "isAvailable": false,
    "languages": null,
    "createdAt": "2025-12-02T...",
    "updatedAt": "2025-12-02T...",
    "totalReviews": 0,
    "averageRating": 0,
    "ratingDistribution": null,
    "lastReviewAt": null
  }
}
```

#### Response (Error - 404)
```json
{
  "error": "用戶不存在",
  "message": "請確保用戶已在 Supabase users 表中創建",
  "firebaseUid": "string"
}
```

---

## ✅ 測試計劃

### 測試場景

#### 1. 首次進入車輛管理頁面
- **預期結果**：自動創建 driver 記錄，`is_available = FALSE`
- **驗證方法**：檢查 Supabase `drivers` 表

#### 2. 再次進入車輛管理頁面
- **預期結果**：返回現有記錄，不創建重複記錄
- **驗證方法**：檢查 Supabase `drivers` 表的記錄數量

#### 3. 刪除記錄後重新進入
- **預期結果**：重新創建 driver 記錄
- **驗證方法**：
  1. 在 Supabase 中刪除 driver 記錄
  2. 重新進入車輛管理頁面
  3. 檢查是否重新創建記錄

#### 4. 用戶未登入
- **預期結果**：記錄警告，不執行 API 調用
- **驗證方法**：檢查日誌輸出

---

## 🚀 部署步驟

### 1. Backend 部署（Railway）
```bash
cd D:\repo\backend
git add src/routes/drivers.ts src/minimal-server.ts
git commit -m "feat: Add driver record auto-generation API endpoint"
git push origin main
```

### 2. Mobile App 部署（Google Play Console）
```bash
cd D:\repo\mobile
git add lib/core/models/driver.dart lib/core/services/driver_service.dart lib/apps/driver/presentation/pages/vehicle_management_page.dart
git commit -m "feat: Auto-generate driver record on first vehicle management page visit"
git push origin main
```

### 3. 構建 Release APK
```bash
cd D:\repo\mobile
flutter build apk --release --flavor driver
```

### 4. 上傳到 Google Play Console
- 進入 Google Play Console
- 選擇 Internal Testing 軌道
- 上傳新的 APK
- 邀請測試人員驗證

---

## 📊 預期結果

✅ **成功標準**：
1. 用戶首次進入車輛管理頁面時，`drivers` 表自動生成記錄
2. `is_available` 欄位初始值為 `FALSE`
3. 再次進入頁面時不會生成重複記錄
4. 刪除記錄後重新進入，能正確重新生成記錄
5. 所有修改已推送到正確的 GitHub 倉庫

---

## 🔍 監控和日誌

### Backend 日誌
- `📥 [DriverService] 確保 driver 記錄存在`
- `✅ [DriverService] 找到用戶 ID`
- `✅ [DriverService] driver 記錄已存在，返回現有記錄`
- `📝 [DriverService] 創建新的 driver 記錄`
- `✅ [DriverService] driver 記錄創建成功`

### Mobile App 日誌
- `📥 [VehicleManagementPage] 確保 driver 記錄存在`
- `📥 [DriverService] 確保 driver 記錄存在`
- `✅ [DriverService] API 調用成功`
- `✅ [DriverService] Driver 記錄解析成功`
- `✅ [VehicleManagementPage] Driver 記錄已確保`

---

## 🎯 後續優化建議

### 1. 添加狀態管理
- 使用 Riverpod 管理 driver 狀態
- 在多個頁面共享 driver 資料

### 2. 添加審核流程
- 在 Web Admin 添加司機審核頁面
- 實作審核通過/拒絕功能
- 實作通知機制（Email + 推播）

### 3. 改善用戶體驗
- 添加載入動畫
- 改善錯誤提示
- 添加重試機制

### 4. 添加測試
- 單元測試：DriverService.ensureDriverRecord()
- 整合測試：API 端點測試
- Widget 測試：車輛管理頁面測試

---

## 📚 相關文檔

- [RelayGo 系統架構](README.md)
- [Release 模式 Email 欄位修復](RELEASE_MODE_EMAIL_FIELD_DIAGNOSIS.md)
- [Supabase 資料庫結構](docs/database-schema.md)

---

**實作完成日期**：2025-12-02  
**實作人員**：Augment Agent  
**版本**：1.0.0

