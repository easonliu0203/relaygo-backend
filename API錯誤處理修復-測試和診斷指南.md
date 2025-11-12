# API 錯誤處理修復 - 測試和診斷指南

**日期**：2025-10-08  
**修復**：API 錯誤處理 FormatException  
**狀態**：✅ 已修復，待測試

---

## 📋 修復摘要

### 問題
```
支付失敗
Exception: 創建預約失敗: FormatException:
Unexpected character (at character 1)
<!DOCTYPE html>...
```

### 根本原因
客戶端在解析 API 錯誤響應時，沒有檢查 Content-Type，假設所有響應都是 JSON。當 API 返回 HTML 錯誤頁面時，JSON 解析失敗。

### 修復方案
1. 添加詳細日誌（URL、狀態碼、Content-Type、響應內容）
2. 檢查響應的 Content-Type
3. 使用 try-catch 包裹 JSON 解析
4. 提供清晰的錯誤訊息

---

## 🚀 測試前準備

### 1. 確保代碼已更新

**檢查修改**：
```bash
# 查看修改後的代碼
cat mobile/lib/core/services/booking_service.dart | grep -A 5 "響應狀態碼"
```

**確認修改**：
- ✅ 添加了詳細日誌
- ✅ 檢查 Content-Type
- ✅ 使用 try-catch 包裹 JSON 解析

---

### 2. 確保管理後台運行

**檢查管理後台**：
```bash
# 測試管理後台首頁
curl http://localhost:3001

# 測試 API 端點
curl -X POST http://localhost:3001/api/bookings \
  -H "Content-Type: application/json" \
  -d '{"test":"data"}'
```

**預期結果**：
- ✅ 首頁返回 HTML
- ✅ API 端點返回 JSON 錯誤

**如果管理後台未運行**：
```bash
cd web-admin
npm run dev
```

---

### 3. 重新建置 App

```bash
# 進入 mobile 目錄
cd mobile

# 清理舊的建置
flutter clean

# 獲取依賴
flutter pub get

# 運行客戶端 App
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

---

## ✅ 測試步驟

### 測試 1：查看詳細日誌（最重要）⭐

#### 目的
修復後，所有 API 請求都會記錄詳細資訊，幫助診斷問題。

#### 步驟
1. 啟動 App（使用 `flutter run`）
2. 創建新訂單
3. 支付訂金
4. 查看控制台日誌

#### 預期日誌

**成功的情況**：
```
[BookingService] 開始創建訂單
[BookingService] 請求 URL: http://10.0.2.2:3001/api/bookings
[BookingService] 響應狀態碼: 200
[BookingService] 響應 Content-Type: application/json
[BookingService] 響應內容: {"success":true,"data":{"id":"...","bookingNumber":"..."}}
[BookingService] API 返回訂單 ID: ...
```

**失敗的情況（JSON 錯誤）**：
```
[BookingService] 開始創建訂單
[BookingService] 請求 URL: http://10.0.2.2:3001/api/bookings
[BookingService] 響應狀態碼: 400
[BookingService] 響應 Content-Type: application/json
[BookingService] 響應內容: {"error":"創建用戶失敗","details":"..."}
[BookingService] 創建預約失敗: Exception: 創建用戶失敗
```

**失敗的情況（HTML 錯誤）**：
```
[BookingService] 開始創建訂單
[BookingService] 請求 URL: http://10.0.2.2:3001/api/bookings
[BookingService] 響應狀態碼: 500
[BookingService] 響應 Content-Type: text/html
[BookingService] 響應內容: <!DOCTYPE html><html><head>...
[BookingService] 創建預約失敗: Exception: API 返回非 JSON 響應 (500)，請檢查管理後台是否正常運行
```

---

#### 診斷問題

**根據日誌診斷**：

1. **如果看到「請求 URL: http://10.0.2.2:3001/api/bookings」**
   - ✅ URL 正確
   - ✅ 客戶端代碼正常

2. **如果看到「響應狀態碼: 200」**
   - ✅ API 調用成功
   - ✅ 管理後台正常運行

3. **如果看到「響應狀態碼: 500」**
   - ❌ API 內部錯誤
   - 需要檢查管理後台日誌

4. **如果看到「響應 Content-Type: text/html」**
   - ❌ API 返回了 HTML 而不是 JSON
   - 可能是 Next.js 錯誤頁面
   - 需要檢查管理後台日誌

5. **如果看到「響應內容: <!DOCTYPE html>」**
   - ❌ 確認是 HTML 響應
   - 查看響應內容預覽（前 200 字元）

6. **如果沒有看到任何日誌**
   - ❌ 請求可能沒有發送
   - 或者網路連接失敗
   - 檢查 Android 模擬器網路設定

---

### 測試 2：完整訂單創建流程

#### 步驟
1. 啟動 App
2. 登入測試帳號
3. 創建新訂單：
   - 上車地點：台北車站
   - 下車地點：台北 101
   - 預約時間：明天 10:00
   - 乘客人數：2 人
4. 點擊「確認預約」
5. 查看控制台日誌

#### 預期結果

**如果成功**：
- ✅ 顯示「預約成功」頁面
- ✅ 日誌顯示「響應狀態碼: 200」
- ✅ 日誌顯示「API 返回訂單 ID: ...」

**如果失敗**：
- ❌ 顯示錯誤訊息
- ✅ 錯誤訊息清晰明確（不再是 FormatException）
- ✅ 日誌記錄完整的請求和響應資訊

---

### 測試 3：支付訂金流程

#### 步驟
1. 創建訂單後
2. 進入支付訂金頁面
3. 選擇支付方式
4. 點擊「確認支付」
5. 查看控制台日誌

#### 預期結果

**如果成功**：
- ✅ 跳轉到「預約成功」頁面
- ✅ 日誌顯示「響應狀態碼: 200」
- ✅ 日誌顯示「支付成功」

**如果失敗**：
- ❌ 顯示錯誤訊息
- ✅ 錯誤訊息清晰明確
- ✅ 日誌記錄完整資訊

---

### 測試 4：網路連接失敗

#### 步驟
1. 停止管理後台
   ```bash
   # 在管理後台終端按 Ctrl+C
   ```
2. 嘗試創建訂單
3. 查看錯誤訊息和日誌

#### 預期結果
- ❌ 顯示錯誤訊息
- ✅ 錯誤訊息提示檢查管理後台
- ✅ 日誌記錄請求 URL
- ✅ 可能顯示「API 返回非 JSON 響應」或網路錯誤

---

## 🔍 故障排除

### 問題 1：仍然出現 FormatException

**症狀**：
```
Exception: 創建預約失敗: FormatException: Unexpected character...
```

**可能原因**：
- 代碼沒有正確更新
- App 沒有重新建置

**解決方案**：
1. 確認代碼已修改
2. 執行 `flutter clean`
3. 重新運行 App
4. 重新測試

---

### 問題 2：看不到詳細日誌

**症狀**：
- 控制台沒有顯示「請求 URL」、「響應狀態碼」等日誌

**可能原因**：
- App 沒有重新建置
- 日誌被過濾

**解決方案**：
1. 確認使用 `flutter run` 啟動 App
2. 檢查控制台過濾設定
3. 搜索 `[BookingService]` 關鍵字

---

### 問題 3：API 返回 HTML

**症狀**：
```
[BookingService] 響應 Content-Type: text/html
[BookingService] 響應內容: <!DOCTYPE html>...
```

**可能原因**：
- API 路由不存在（404）
- API 內部錯誤（500）
- Next.js 返回錯誤頁面

**解決方案**：

**檢查 API 路由**：
```bash
# 測試創建訂單 API
curl -X POST http://localhost:3001/api/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "customerUid": "test-uid",
    "pickupAddress": "台北車站",
    "pickupLatitude": 25.0478,
    "pickupLongitude": 121.5170,
    "dropoffAddress": "台北 101",
    "dropoffLatitude": 25.0339,
    "dropoffLongitude": 121.5645,
    "bookingTime": "2025-10-09T10:00:00Z",
    "passengerCount": 2,
    "luggageCount": 0,
    "notes": "",
    "packageId": "",
    "packageName": "",
    "estimatedFare": 0
  }'
```

**檢查管理後台日誌**：
1. 查看管理後台終端
2. 尋找錯誤訊息
3. 檢查 API 路由是否正確

**檢查 API 路由文件**：
- `web-admin/src/app/api/bookings/route.ts`
- `web-admin/src/app/api/bookings/[id]/pay-deposit/route.ts`
- `web-admin/src/app/api/bookings/[id]/cancel/route.ts`

---

### 問題 4：Android 模擬器無法訪問 localhost

**症狀**：
- 請求超時
- 無法連接到伺服器

**可能原因**：
- Android 模擬器無法訪問 `http://10.0.2.2:3001`
- 防火牆阻擋連接

**解決方案**：

**測試連接**：
```bash
# 在 Android 模擬器中測試
adb shell curl http://10.0.2.2:3001
```

**檢查防火牆**：
1. 確認 Windows 防火牆允許 Node.js
2. 確認管理後台監聽 `0.0.0.0:3001` 而不是 `localhost:3001`

**修改 _baseUrl**（臨時測試）：
```dart
// 使用實際 IP 地址
static const String _baseUrl = 'http://192.168.1.100:3001/api';
```

---

### 問題 5：API 返回「創建用戶失敗」

**症狀**：
```json
{
  "error": "創建用戶失敗",
  "details": "null value in column \"firebase_uid\" of relation \"users\" violates not-null constraint"
}
```

**原因**：
- 用戶在 Supabase `users` 表中不存在
- API 嘗試創建用戶但 `firebase_uid` 為 null

**解決方案**：

**檢查用戶登入**：
```dart
final user = FirebaseAuth.instance.currentUser;
print('當前用戶 UID: ${user?.uid}');
```

**手動創建用戶**（臨時解決）：
```sql
-- 在 Supabase SQL Editor 中執行
INSERT INTO users (firebase_uid, email, display_name, role)
VALUES ('測試用戶的UID', 'test@example.com', '測試用戶', 'customer');
```

**檢查 API 代碼**：
- 確認 API 正確處理用戶創建
- 確認 `firebase_uid` 正確傳遞

---

## 📊 診斷流程圖

```
開始測試
    ↓
創建訂單
    ↓
查看日誌
    ↓
是否看到「請求 URL」？
    ├─ 否 → App 沒有重新建置 → 執行 flutter clean
    └─ 是 → 繼續
        ↓
    是否看到「響應狀態碼」？
        ├─ 否 → 網路連接失敗 → 檢查管理後台、防火牆
        └─ 是 → 繼續
            ↓
        狀態碼是多少？
            ├─ 200 → ✅ 成功！
            ├─ 400/422 → 驗證錯誤 → 檢查請求參數
            ├─ 404 → API 路由不存在 → 檢查 API 路由文件
            ├─ 500 → API 內部錯誤 → 檢查管理後台日誌
            └─ 其他 → 查看響應內容
                ↓
            Content-Type 是什麼？
                ├─ application/json → 查看錯誤訊息 → 修復 API 問題
                └─ text/html → API 返回 HTML → 檢查管理後台日誌
```

---

## 💡 診斷技巧

### 1. 使用 Flutter DevTools

```bash
# 啟動 App 時自動打開 DevTools
flutter run --flavor customer --target lib/apps/customer/main_customer.dart --devtools
```

**查看**：
- Logging（查看所有日誌）
- Network（查看網路請求）
- Debugger（設置斷點）

---

### 2. 使用 curl 測試 API

```bash
# 測試創建訂單 API
curl -X POST http://localhost:3001/api/bookings \
  -H "Content-Type: application/json" \
  -d '{"customerUid":"test","pickupAddress":"台北車站",...}' \
  -v

# 測試支付訂金 API
curl -X POST http://localhost:3001/api/bookings/{訂單ID}/pay-deposit \
  -H "Content-Type: application/json" \
  -d '{"customerUid":"test","paymentMethod":"credit_card"}' \
  -v
```

---

### 3. 查看管理後台日誌

**Next.js 開發伺服器日誌**：
- 查看管理後台終端
- 尋找 API 請求日誌
- 檢查錯誤堆棧追蹤

---

### 4. 使用 Postman 或 Insomnia

**優點**：
- 圖形化界面
- 可以保存請求
- 可以查看詳細的響應

**測試步驟**：
1. 創建新請求
2. 設置 URL：`http://localhost:3001/api/bookings`
3. 設置方法：POST
4. 設置 Headers：`Content-Type: application/json`
5. 設置 Body：JSON 格式的請求資料
6. 發送請求
7. 查看響應

---

## 📈 預期時間線

### 正常流程時間線

```
T+0s:  用戶點擊「確認預約」
T+0s:  調用 createBookingWithSupabase()
T+0s:  記錄「請求 URL」
T+0s:  發送 POST 請求
T+1s:  收到響應
T+1s:  記錄「響應狀態碼」、「Content-Type」、「響應內容」
T+1s:  檢查狀態碼 = 200 ✅
T+1s:  解析 JSON
T+1s:  返回訂單資料
T+1s:  顯示「預約成功」頁面 ✅
```

---

### 錯誤流程時間線（修復後）

```
T+0s:  用戶點擊「確認預約」
T+0s:  調用 createBookingWithSupabase()
T+0s:  記錄「請求 URL」
T+0s:  發送 POST 請求
T+1s:  收到響應
T+1s:  記錄「響應狀態碼: 500」
T+1s:  記錄「Content-Type: text/html」
T+1s:  記錄「響應內容: <!DOCTYPE html>...」
T+1s:  檢查狀態碼 ≠ 200
T+1s:  檢查 Content-Type ≠ application/json
T+1s:  拋出錯誤：「API 返回非 JSON 響應 (500)，請檢查管理後台是否正常運行」✅
T+1s:  顯示錯誤訊息 ✅
T+1s:  開發者查看日誌診斷問題 ✅
```

---

## ✅ 成功標準

### 修復成功的標誌

1. **不再出現 FormatException** ⭐
   - 這是最重要的指標
   - 即使 API 返回 HTML，也不會拋出 FormatException

2. **錯誤訊息清晰明確**
   - 不再顯示技術細節（FormatException）
   - 顯示有用的錯誤訊息
   - 提供可操作的建議

3. **日誌記錄完整**
   - 記錄請求 URL
   - 記錄響應狀態碼
   - 記錄響應 Content-Type
   - 記錄響應內容預覽

4. **可以診斷問題**
   - 根據日誌可以判斷問題所在
   - 可以區分網路問題、API 問題、資料問題

---

## 📚 相關文檔

1. **`docs/20251008_2026_17_API錯誤處理FormatException修復.md`**
   - 完整的問題診斷和修復過程

2. **`mobile/lib/core/services/booking_service.dart`**
   - 修改後的訂單服務類

3. **Flutter 官方文檔**
   - https://dart.dev/guides/libraries/library-tour#dartconvert
   - https://api.flutter.dev/flutter/dart-convert/json-constant.html

---

**修復狀態**：✅ 已完成  
**測試狀態**：⏳ 待執行

🚀 **請立即測試訂單創建和支付流程，查看詳細日誌！**

**最重要的測試**：
1. 重新建置 App（`flutter clean` + `flutter run`）
2. 創建新訂單
3. 查看控制台日誌
4. ✅ 確認看到「請求 URL」、「響應狀態碼」等日誌
5. ✅ 確認不再出現 FormatException
6. ✅ 根據日誌診斷問題

**如果看到錯誤**：
- 查看日誌中的「響應狀態碼」
- 查看日誌中的「Content-Type」
- 查看日誌中的「響應內容」
- 根據這些資訊診斷問題
- 參考「故障排除」章節

