# 修復工作快速參考指南

**最後更新**：2025-10-08 21:00  
**狀態**：✅ 所有修復已完成，待測試

---

## 🚀 快速開始

### 1. 重啟管理後台（必須）⭐

```bash
# 停止管理後台（Ctrl+C）
cd web-admin
npm run dev
```

**確認成功**：
```
✓ Ready in 2.5s
○ Local:        http://localhost:3001
```

---

### 2. 測試 API 端點

```bash
curl -X POST http://localhost:3001/api/bookings/test-id/cancel \
  -H "Content-Type: application/json" \
  -d '{"customerUid":"test-uid","reason":"測試取消功能"}'
```

**預期結果**：
```json
{"success":false,"error":"訂單不存在"}
```

---

### 3. 重新建置 Flutter App

```bash
cd mobile
flutter clean
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

---

### 4. 測試取消訂單功能

1. 創建訂單 → 支付訂金
2. 進入訂單詳情
3. 點擊「取消訂單」
4. 輸入取消原因並確認
5. ✅ 確認顯示「訂單已取消」

---

## 📚 文檔索引

### 開發歷程文檔

| 編號 | 時間 | 主題 | 文檔 |
|------|------|------|------|
| #15 | 07:38 | Firestore 權限錯誤修復 | `docs/20251008_0738_15_Firestore權限錯誤修復.md` |
| #16 | 19:35 | TextEditingController 錯誤修復 | `docs/20251008_1935_16_取消訂單TextEditingController錯誤修復.md` |
| #17 | 20:26 | API 錯誤處理修復 | `docs/20251008_2026_17_API錯誤處理FormatException修復.md` |
| #18 | 20:47 | API 模組導入錯誤修復 | `docs/20251008_2047_18_取消訂單API模組導入錯誤修復.md` |
| #19 | 21:00 | 今日修復工作總覽 | `docs/20251008_2100_19_今日修復工作總覽.md` |

### 測試和部署指南

| 主題 | 文檔 |
|------|------|
| Firestore 權限修復部署 | `Firestore權限錯誤修復-部署指南.md` |
| Firestore 權限修復測試 | `Firestore權限修復-驗證測試.md` |
| API 錯誤處理測試 | `API錯誤處理修復-測試和診斷指南.md` |
| 取消訂單功能測試 | `取消訂單功能-完整測試指南.md` |
| 快速參考 | `README-修復工作快速參考.md`（本文檔） |

---

## 🔧 修復摘要

### 修復 #1：Firestore 權限錯誤

**問題**：`permission-denied` 錯誤  
**原因**：文檔不存在時 `resource.data` 為 null  
**修復**：使用 `exists()` 函數允許讀取不存在的文檔  
**文件**：`firebase/firestore.rules`

---

### 修復 #2：TextEditingController 錯誤

**問題**：`_dependents.isEmpty` 斷言失敗  
**原因**：在對話框關閉前 dispose controller  
**修復**：使用 `.then()` 回調在對話框關閉後 dispose  
**文件**：`mobile/lib/apps/customer/presentation/pages/order_detail_page.dart`

---

### 修復 #3：API 錯誤處理

**問題**：`FormatException` 錯誤  
**原因**：假設 API 總是返回 JSON  
**修復**：檢查 Content-Type + 詳細日誌 + try-catch  
**文件**：`mobile/lib/core/services/booking_service.dart`

---

### 修復 #4：API 模組導入錯誤

**問題**：`Module not found: Can't resolve '@/lib/database'`  
**原因**：錯誤的模組路徑  
**修復**：改為 `@/lib/supabase`  
**文件**：`web-admin/src/app/api/bookings/[id]/cancel/route.ts`

---

## 🐛 常見問題

### Q1: 管理後台仍然顯示編譯錯誤？

**檢查**：
```bash
cat web-admin/src/app/api/bookings/[id]/cancel/route.ts | grep "lib/supabase"
```

**應該看到**：
```typescript
import { DatabaseService } from '@/lib/supabase';
```

**如果沒有**：
- 代碼沒有正確更新
- 手動修改第 2 行
- 重啟管理後台

---

### Q2: API 仍然返回 HTML？

**檢查管理後台終端**：
- 是否有編譯錯誤？
- 是否顯示「Ready in ...ms」？

**解決方案**：
1. 重啟管理後台
2. 確認沒有錯誤
3. 重新測試

---

### Q3: Flutter App 仍然出現 `_dependents.isEmpty` 錯誤？

**檢查**：
```bash
cat mobile/lib/apps/customer/presentation/pages/order_detail_page.dart | grep -A 5 ".then((reason)"
```

**應該看到**：
```dart
).then((reason) async {
  reasonController.dispose();
  ...
});
```

**如果沒有**：
- 代碼沒有正確更新
- 執行 `flutter clean`
- 重新運行 App

---

### Q4: 如何查看詳細日誌？

**Flutter 控制台**：
```
[BookingService] 請求 URL: ...
[BookingService] 響應狀態碼: ...
[BookingService] 響應 Content-Type: ...
[BookingService] 響應內容: ...
```

**管理後台終端**：
```
🚫 收到取消訂單請求: ...
📋 找到訂單: ...
✅ 訂單已取消: ...
```

---

## 📊 測試檢查清單

### 管理後台
- [ ] 重啟管理後台
- [ ] 確認沒有編譯錯誤
- [ ] 測試 API 端點（curl）
- [ ] 確認返回 JSON

### Flutter App
- [ ] 重新建置 App
- [ ] 創建測試訂單
- [ ] 支付訂金
- [ ] 測試取消訂單
- [ ] 確認不出現錯誤

### 資料驗證
- [ ] 檢查 Supabase `bookings` 表
- [ ] 檢查 Supabase `outbox` 表
- [ ] 檢查 Firestore 同步

---

## 🔍 診斷流程

### 如果取消訂單失敗

**步驟 1：查看 Flutter 日誌**
```
[BookingService] 響應狀態碼: ???
[BookingService] 響應 Content-Type: ???
```

**步驟 2：根據狀態碼診斷**
- `200` → ✅ 成功
- `400` → 驗證錯誤（檢查取消原因）
- `403` → 權限錯誤（檢查用戶 UID）
- `404` → 訂單不存在（檢查訂單 ID）
- `500` → API 內部錯誤（檢查管理後台日誌）

**步驟 3：根據 Content-Type 診斷**
- `application/json` → API 正常，檢查錯誤訊息
- `text/html` → API 編譯失敗，檢查管理後台

**步驟 4：查看管理後台日誌**
- 尋找錯誤訊息
- 檢查堆棧追蹤
- 確認 API 邏輯

---

## 💡 關鍵提示

### 1. 總是重啟管理後台

修改 API 代碼後，**必須**重啟管理後台：
```bash
# Ctrl+C 停止
npm run dev
```

---

### 2. 總是重新建置 Flutter App

修改 Flutter 代碼後，**建議**重新建置：
```bash
flutter clean
flutter pub get
flutter run ...
```

---

### 3. 查看詳細日誌

所有 API 請求都會記錄詳細資訊：
- 請求 URL
- 響應狀態碼
- 響應 Content-Type
- 響應內容預覽

---

### 4. 使用 curl 快速測試

不需要啟動 Flutter App 就可以測試 API：
```bash
curl -X POST http://localhost:3001/api/bookings/test-id/cancel \
  -H "Content-Type: application/json" \
  -d '{"customerUid":"test-uid","reason":"測試取消功能"}'
```

---

## 🎯 成功標準

### 管理後台
- ✅ 沒有編譯錯誤
- ✅ 顯示「Ready in ...ms」
- ✅ API 返回 JSON（不是 HTML）

### Flutter App
- ✅ 對話框正常關閉
- ✅ 不出現 `_dependents.isEmpty` 錯誤
- ✅ 不出現 `FormatException` 錯誤
- ✅ 顯示「訂單已取消」訊息

### 資料同步
- ✅ Supabase `bookings` 表已更新
- ✅ Supabase `outbox` 表有事件
- ✅ Firestore 已同步

---

## 📞 需要幫助？

### 查看詳細文檔

**問題診斷**：
- `docs/20251008_2100_19_今日修復工作總覽.md`

**測試指南**：
- `取消訂單功能-完整測試指南.md`
- `API錯誤處理修復-測試和診斷指南.md`

**修復細節**：
- 查看對應的開發歷程文檔（#15-#18）

---

### 常用命令

**重啟管理後台**：
```bash
cd web-admin
npm run dev
```

**重新建置 Flutter App**：
```bash
cd mobile
flutter clean && flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

**測試 API**：
```bash
curl -X POST http://localhost:3001/api/bookings/test-id/cancel \
  -H "Content-Type: application/json" \
  -d '{"customerUid":"test-uid","reason":"測試取消功能"}'
```

**檢查代碼**：
```bash
# 檢查 API 導入
grep "lib/supabase" web-admin/src/app/api/bookings/[id]/cancel/route.ts

# 檢查 Flutter 修復
grep -A 5 ".then((reason)" mobile/lib/apps/customer/presentation/pages/order_detail_page.dart
```

---

**狀態**：✅ 所有修復已完成  
**下一步**：執行測試檢查清單

🚀 **開始測試吧！**

