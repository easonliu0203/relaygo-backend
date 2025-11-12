# 🚨 公司端網路連接錯誤 - 快速修復

**錯誤**: Network Error - 網路連接失敗  
**狀態**: ✅ 已修復

---

## ⚡ 立即執行步驟

### 步驟 1: 確認修復已應用

所有修復已自動完成，無需手動操作。

### 步驟 2: 重新啟動管理後台

```bash
cd web-admin
npm run dev
```

### 步驟 3: 測試訂單管理頁面

**訪問**: http://localhost:3001/orders

**預期結果**:
- ✅ 頁面正常載入
- ✅ 不出現 "Network Error"
- ✅ 顯示真實訂單資料
- ✅ 統計數據正確顯示

---

## 🔧 已完成的修復

### 問題根源

**錯誤的 API 請求流程**:
```
前端調用 ApiService.getBookings()
  ↓
使用 apiClient (baseURL = 'http://localhost:3000')
  ↓
請求 http://localhost:3000/api/admin/bookings  ❌ 錯誤！
  ↓
Network Error（該端點不存在於後端服務器）
```

**正確的 API 請求流程**:
```
前端調用 ApiService.getBookings()
  ↓
使用 internalApiClient (baseURL = '')
  ↓
請求 http://localhost:3001/api/admin/bookings  ✅ 正確！
  ↓
成功返回訂單資料
```

### 修復內容

#### 1. 創建內部 API 客戶端

**文件**: `web-admin/src/services/api.ts`

**新增代碼**:
```typescript
// 創建外部 API axios 實例（用於後端服務器）
const apiClient: AxiosInstance = axios.create({
  baseURL: 'http://localhost:3000',  // 外部後端 API
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 創建內部 API axios 實例（用於 Next.js API 路由）
const internalApiClient: AxiosInstance = axios.create({
  baseURL: '',  // ✅ 使用相對路徑，調用 Next.js 自己的 API
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});
```

#### 2. 添加內部 API 請求方法

**新增方法**:
```typescript
// 內部 API 請求方法（用於 Next.js API 路由）
static async internalGet<T = any>(url: string, config?: AxiosRequestConfig): Promise<T> {
  const response = await internalApiClient.get(url, config);
  return response.data;
}

static async internalPost<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
  const response = await internalApiClient.post(url, data, config);
  return response.data;
}

static async internalPut<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
  const response = await internalApiClient.put(url, data, config);
  return response.data;
}

static async internalDelete<T = any>(url: string, config?: AxiosRequestConfig): Promise<T> {
  const response = await internalApiClient.delete(url, config);
  return response.data;
}
```

#### 3. 修改訂單管理方法

**修改前**:
```typescript
static async getBookings(params?: any) {
  return this.get('/api/admin/bookings', { params });  // ❌ 使用外部 API
}
```

**修改後**:
```typescript
static async getBookings(params?: any) {
  return this.internalGet('/api/admin/bookings', { params });  // ✅ 使用內部 API
}
```

#### 4. 修改其他內部 API 方法

**已修改的方法**:
- ✅ `login()` - 使用 `internalPost`
- ✅ `logout()` - 使用 `internalPost`
- ✅ `getProfile()` - 使用 `internalGet`
- ✅ `getDashboardStats()` - 使用 `internalGet`
- ✅ `getBookings()` - 使用 `internalGet`
- ✅ `getBookingById()` - 使用 `internalGet`
- ✅ `updateBooking()` - 使用 `internalPut`

---

## 🔍 問題診斷

### 為什麼會出現 Network Error?

**架構說明**:
- **Next.js API 路由**: 在 web-admin 內部（port 3001）
  - 例如: `/api/admin/bookings`, `/api/auth/admin/login`
- **後端 API**: 在 backend 服務器（port 3000）
  - 例如: `/api/booking-flow/*`

**錯誤原因**:
- 所有 API 請求都使用同一個 `apiClient`
- `apiClient` 的 `baseURL` 設置為 `http://localhost:3000`
- Next.js API 路由請求發送到了後端服務器
- 後端服務器沒有這些端點
- 導致 Network Error

**修復方法**:
- 創建兩個 axios 實例
- `apiClient`: 用於外部後端 API
- `internalApiClient`: 用於 Next.js API 路由
- 根據 API 類型使用不同的客戶端

---

## ✅ 驗證修復

### 方法 1: 使用測試腳本

```bash
chmod +x test-network-fix.sh
./test-network-fix.sh
```

**預期結果**:
- ✅ 所有測試返回 HTTP 200
- ✅ 返回正確的 JSON 資料
- ✅ 不出現 Network Error

### 方法 2: 檢查瀏覽器開發者工具

**打開瀏覽器開發者工具** (F12):

1. **Network 標籤**:
   - 訪問 http://localhost:3001/orders
   - 查看 `/api/admin/bookings` 請求
   - ✅ 請求 URL: `http://localhost:3001/api/admin/bookings`
   - ✅ 狀態碼: 200
   - ✅ 回應資料: 訂單列表

2. **Console 標籤**:
   - ✅ 顯示 "🚀 Internal API Request: GET /api/admin/bookings"
   - ✅ 顯示 "✅ Internal API Response: GET /api/admin/bookings"
   - ✅ 不出現錯誤訊息

### 方法 3: 測試訂單管理頁面

**訪問**: http://localhost:3001/orders

**驗證項目**:
- ✅ 頁面正常載入
- ✅ 不出現 "Network Error"
- ✅ 顯示真實訂單資料
- ✅ 統計數據正確顯示（不是全部為 0）
- ✅ 搜尋、篩選功能正常

---

## 🔍 如果仍有問題

### 問題 1: 仍然出現 Network Error

**可能原因**: 瀏覽器快取

**解決**:
1. 清除瀏覽器快取
2. 硬性重新整理（Ctrl + Shift + R）
3. 或使用無痕模式

### 問題 2: 頁面顯示「暫無訂單資料」

**可能原因**: Supabase 中沒有訂單資料

**解決**:
1. 檢查 Supabase 資料庫:
   ```sql
   SELECT COUNT(*) FROM bookings;
   ```

2. 如果沒有資料，使用客戶端應用創建測試訂單

### 問題 3: 出現其他錯誤

**可能原因**: Supabase 連接問題

**解決**:
1. 檢查 `.env.local` 文件:
   ```
   NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_key
   ```

2. 重新啟動管理後台:
   ```bash
   cd web-admin
   npm run dev
   ```

---

## 📊 修復對比

### 修復前

**API 請求**:
- ❌ 請求 URL: `http://localhost:3000/api/admin/bookings`
- ❌ 錯誤: Network Error
- ❌ 原因: 後端服務器沒有這個端點

**頁面狀態**:
- ❌ 顯示 "Network Error"
- ❌ 統計數據全部為 0
- ❌ 表格顯示「暫無訂單資料」
- ❌ 右上角紅色錯誤提示

### 修復後

**API 請求**:
- ✅ 請求 URL: `http://localhost:3001/api/admin/bookings`
- ✅ 狀態碼: 200
- ✅ 回應: 正確的訂單資料

**頁面狀態**:
- ✅ 正常載入
- ✅ 統計數據正確顯示
- ✅ 表格顯示真實訂單
- ✅ 所有功能正常工作

---

## 💡 為什麼會出現這個問題?

**架構混淆**:
- Next.js 有兩種 API:
  1. **內部 API 路由** (在 `app/api/` 下)
  2. **外部後端 API** (獨立的後端服務器)

**配置錯誤**:
- 所有 API 請求都使用同一個配置
- `baseURL` 設置為外部後端服務器
- 導致內部 API 路由請求發送到錯誤的地方

**教訓**:
- 需要清楚區分內部和外部 API
- 使用不同的配置處理不同類型的 API
- 檢查實際的請求 URL，而不是假設

---

## 📚 詳細文檔

查看完整說明: `docs/20251009_0200_21_公司端網路連接錯誤修復.md`

---

## 🎉 預期效果

1. ✅ 公司端訂單管理頁面正常顯示訂單
2. ✅ 不再出現 "Network Error"
3. ✅ 統計數據正確顯示
4. ✅ 搜尋、篩選、分頁功能正常
5. ✅ 所有訂單相關頁面都能正常工作

---

**需要幫助?** 查看 `docs/20251009_0200_21_公司端網路連接錯誤修復.md` 獲取詳細說明!

